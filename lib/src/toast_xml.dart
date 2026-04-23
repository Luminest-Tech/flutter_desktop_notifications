import '../notification_message.dart';

String _escapeXml(String s) {
  final sb = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x26:
        sb.write('&amp;');
      case 0x3C:
        sb.write('&lt;');
      case 0x3E:
        sb.write('&gt;');
      case 0x22:
        sb.write('&quot;');
      case 0x27:
        sb.write('&apos;');
      default:
        sb.writeCharCode(r);
    }
  }
  return sb.toString();
}

/// Builds the full toast XML for a plugin-template [message]. The caller is
/// expected to use [NotificationMessage.fromPluginTemplate]; this function
/// does not validate that.
String buildPluginTemplateXml(NotificationMessage message) {
  final sb = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n');
  sb.write('<toast activationType="protocol">\n');
  sb.write('  <visual>\n');
  sb.write('    <binding template="ToastGeneric">\n');
  if (message.title != null) {
    sb.write('      <text>${_escapeXml(message.title!)}</text>\n');
  }
  if (message.body != null) {
    sb.write('      <text>${_escapeXml(message.body!)}</text>\n');
  }
  if (message.image != null) {
    sb.write(
        '      <image placement="appLogoOverride" hint-crop="circle" src="${_escapeXml(message.image!)}"/>\n');
  }
  if (message.largeImage != null) {
    sb.write('      <image src="${_escapeXml(message.largeImage!)}"/>\n');
  }
  sb.write('    </binding>\n');
  sb.write('  </visual>\n');

  if (message.actions.isNotEmpty || message.inputs.isNotEmpty) {
    sb.write('  <actions>\n');
    for (final input in message.inputs) {
      sb.write('    <input id="${_escapeXml(input.id)}" type="${input.type}"');
      if (input.title != null) {
        sb.write(' title="${_escapeXml(input.title!)}"');
      }
      if (input.placeholder != null) {
        sb.write(' placeHolderContent="${_escapeXml(input.placeholder!)}"');
      }
      if (input.defaultSelectionId != null) {
        sb.write(' defaultInput="${_escapeXml(input.defaultSelectionId!)}"');
      }
      if (input.selections.isEmpty) {
        sb.write('/>\n');
      } else {
        sb.write('>\n');
        for (final sel in input.selections) {
          sb.write(
              '      <selection id="${_escapeXml(sel.id)}" content="${_escapeXml(sel.content)}"/>\n');
        }
        sb.write('    </input>\n');
      }
    }
    for (final a in message.actions) {
      sb.write('    <action');
      sb.write(' content="${_escapeXml(a.content)}"');
      sb.write(' arguments="${_escapeXml(a.arguments)}"');
      sb.write(' activationType="${a.activationType.name}"');
      if (a.imageUri != null) {
        sb.write(' imageUri="${_escapeXml(a.imageUri!)}"');
      }
      if (a.inputId != null) {
        sb.write(' hint-inputId="${_escapeXml(a.inputId!)}"');
      }
      if (a.buttonStyle != null) {
        sb.write(' hint-buttonStyle="${a.buttonStyle!.name}"');
      }
      sb.write('/>\n');
    }
    sb.write('  </actions>\n');
  }
  sb.write('</toast>\n');
  return sb.toString();
}
