import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';

import 'net.dart';

// portal.amfiindia.com/spages/NAVAll.txt, probed 2026-10-14 (www.amfiindia.com 302s here):
// ~1.5 MB, every open scheme's latest NAV. Section lines "Open Ended Schemes(<category>)",
// then AMC name lines, then rows "code;isinGrowth;isinReinv;name;plan;option;nav;dd-Mon-yyyy".
// Plan is "Direct Plan" / "Regular Plan" (legacy rows leave plan and option empty).

class FundRow {
  final String code;
  final String name;
  final String category; // e.g. "Flexi Cap Fund"
  final int navE4;
  const FundRow(this.code, this.name, this.category, this.navE4);
}

/// Equity categories the advisor ranks (AMFI names after normalising).
const fundCategories = [
  'Large Cap Fund',
  'Flexi Cap Fund',
  'Large & Mid Cap Fund',
  'Mid Cap Fund',
  'Small Cap Fund',
  'Multi Cap Fund',
  'ELSS',
  'Focused Fund',
  'Value Fund',
];

String _category(String header) {
  final m = RegExp(r'\((.*)\)\s*$').firstMatch(header);
  var c = m?.group(1) ?? header;
  c = c.replaceFirst(RegExp(r'^Equity Schemes? - '), '');
  if (c.startsWith('ELSS')) c = 'ELSS';
  return c.trim();
}

final _growth = RegExp(r'^(direct )?growth( option)*$');

/// Direct-plan growth options in [fundCategories] only.
List<FundRow> parseNavAll(String body) {
  final out = <FundRow>[];
  String? cat;
  for (final raw in body.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('Open Ended') || line.startsWith('Close Ended') || line.startsWith('Interval')) {
      final c = line.startsWith('Open Ended') ? _category(line) : null;
      cat = fundCategories.contains(c) ? c : null;
      continue;
    }
    if (cat == null) continue;
    final p = line.split(';');
    if (p.length < 8 || !RegExp(r'^\d{3,7}$').hasMatch(p[0].trim())) continue;
    final opt = p[5].trim().toLowerCase().replaceAll(RegExp(r'[()]'), '');
    if (p[4].trim() != 'Direct Plan' || !_growth.hasMatch(opt)) continue;
    final nav = decimalE4(p[6].trim());
    if (nav == null || nav <= 0) continue;
    out.add(FundRow(p[0].trim(), p[3].trim(), cat, nav));
  }
  return out;
}

// portal.amfiindia.com chains to "Sectigo Public Server Authentication Root R46", a public root in
// the Mozilla and Windows stores that some Android versions do not ship yet (TLS fails with
// CERTIFICATE_VERIFY_FAILED). Trusted here for this one client only, on top of the system roots.
// SHA-256 7B:B6:47:A6:2A:EE:AC:88:BF:25:7A:A5:22:D0:1F:FE:A3:95:E0:AB:45:C7:3F:93:F6:56:54:EC:38:F2:5A:06,
// exported from the Windows root store and checked against the live chain (2026-10-14).
const _sectigoR46 = '''
-----BEGIN CERTIFICATE-----
MIIFijCCA3KgAwIBAgIQdY39i658BwD6qSWn4cetFDANBgkqhkiG9w0BAQwFADBfMQswCQYDVQQG
EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMTYwNAYDVQQDEy1TZWN0aWdvIFB1YmxpYyBT
ZXJ2ZXIgQXV0aGVudGljYXRpb24gUm9vdCBSNDYwHhcNMjEwMzIyMDAwMDAwWhcNNDYwMzIxMjM1
OTU5WjBfMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMTYwNAYDVQQDEy1T
ZWN0aWdvIFB1YmxpYyBTZXJ2ZXIgQXV0aGVudGljYXRpb24gUm9vdCBSNDYwggIiMA0GCSqGSIb3
DQEBAQUAA4ICDwAwggIKAoICAQCTvtU2UnXYASOgHEdCSe5jtrch/cSV1UgrJnwUUxDaef0rty2k
1Cz66jLdScK5vQ9IPXtamFSvnl0xdE8H/FAh3aTPaE8bEmNtJZlMKpnzSDBh+oF8HqcIStw+Kxwf
GExxqjWMrfhu6DtK2eWUAtaJhBOqbchPM8xQljeSM9xfiOefVNlI8JhD1mb9nxc4Q8UBUQvX4yMP
FF1bFOdLvt30yNoDN9HWOaEhUTCDsG3XME6WW5HwcCSrv0WBZEMNvSE6Lzzpng3LILVCJ8zab5vu
ZDCQOc2TZYEhMbUjUDM3IuM47fgxMMxF/mL50V0yeUKH32rMVhlATc6qu/m1dkmU8Sf4kaWD5Qaz
Yw6A3OASVYCmO2a0OYctyPDQ0RTp5A1NDvZdV3LFOxxHVp3i1fuBYYzMTYCQNFu31xR13NgESJ/A
wSiItOkcyqex8Va3e0lMWeUgFaiEAin6OJRpmkkGj80feRQXEgyDet4fsZfu+Zd4KKTIRJLpfSYF
plhym3kT2BFfrsU4YjRosoYwjviQYZ4ybPUHNs2iTG7sijbt8uaZFURww3y8nDnAtOFr94MlI1fZ
EoDlSfB1D++N6xybVCi0ITz8fAr/73trdf+LHaAZBav6+CuBQug4urv7qv094PPK306Xlynt8xhW
6aWWrL3DkJiy4Pmi1KZHQ3xtzwIDAQABo0IwQDAdBgNVHQ4EFgQUVnNYZJX5khqwEioEYnmhQBWI
IUkwDgYDVR0PAQH/BAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEMBQADggIBAC9c
mTz8Bl6MlC5w6tIyMY208FHVvArzZJ8HXtXBc2hkeqK5Duj5XYUtqDdFqij0lgVQYKlJfp/imTYp
E0RHap1VIDzYm/EDMrraQKFz6oOht0SmDpkBm+S8f74TlH7Kph52gDY9hAaLMyZlbcp+nv4fjFg4
exqDsQ+8FxG75gbMY/qB8oFM2gsQa6H61SilzwZAFv97fRheORKkU55+MkIQpiGRqRxOF3yEvJ+M
0ejf5lG5Nkc/kLnHvALcWxxPDkjBJYOcCj+esQMzEhonrPcibCTRAUH4WAP+JWgiH5paPHxsnnVI
84HxZmduTILA7rpXDhjvLpr3Etiga+kFpaHpaPi8TD8SHkXoUsCjvxInebnMMTzD9joiFgOgyY9m
pFuiTdaBJQbpdqQACj7LzTWb4OE4y2BThihCQRxEV+ioratF4yUQvNs+ZUH7G6aXD+u5dHn5Hrwd
Vw1Hr8Mvn4dGp+smWg9WY7ViYG4A++MnESLn/pmPNPW56MORcr3Ywx65LvKRRFHQV80MNNVIIb/b
E/FmJUNS0nAiNs2fxBx1IK1jcmMGDw4nztJqDby1ORrp0XZ60Vzk50lJLVU3aPAaOpg+VBeHVOmm
J1CJeyAvP/+/oYtKR5j/K3tJPsMpRmAYQqszKbrAKbkTidOIijlBO8n9pu0f9GBj39ItVQGL
-----END CERTIFICATE-----
''';

/// Net for AMFI: system roots plus Sectigo R46, 30 s timeout (NAVAll is ~1.5 MB).
Net amfiNet() {
  final ctx = SecurityContext(withTrustedRoots: true)..setTrustedCertificatesBytes(utf8.encode(_sectigoR46));
  return Net(client: IOClient(HttpClient(context: ctx)), timeout: const Duration(seconds: 30));
}

Future<List<FundRow>> amfiFunds(Net n) async =>
    parseNavAll((await n.get('amfi', Uri.parse('https://portal.amfiindia.com/spages/NAVAll.txt'))).body);
