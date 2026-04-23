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

String _scenarioAttr(NotificationScenario s) => switch (s) {
      NotificationScenario.defaultScenario => 'default',
      NotificationScenario.reminder => 'reminder',
      NotificationScenario.alarm => 'alarm',
      NotificationScenario.incomingCall => 'incomingCall',
      NotificationScenario.urgent => 'urgent',
    };

String _textTag(NotificationText t) {
  final attrs = <String>[];
  if (t.style != null) attrs.add('hint-style="${t.style!.name}"');
  if (t.alignment != null) attrs.add('hint-align="${t.alignment!.name}"');
  if (t.maxLines != null) attrs.add('hint-maxLines="${t.maxLines}"');
  final open = attrs.isEmpty ? '<text>' : '<text ${attrs.join(' ')}>';
  return '$open${_escapeXml(t.content)}</text>';
}

String buildPluginTemplateXml(NotificationMessage message) {
  final sb = StringBuffer('<?xml version="1.0" encoding="utf-8"?>\n');

  final activation =
      message.activationType ?? NotificationActivationType.foreground;
  sb.write('<toast activationType="${activation.name}"');
  if (message.scenario != null) {
    sb.write(' scenario="${_scenarioAttr(message.scenario!)}"');
  }
  if (message.duration != null) {
    sb.write(' duration="${message.duration!.name}"');
  }
  if (message.displayTimestamp != null) {
    sb.write(
        ' displayTimestamp="${message.displayTimestamp!.toUtc().toIso8601String()}"');
  }
  final anyStyled =
      message.actions.any((a) => a.buttonStyle != null && !a.contextMenu);
  if (anyStyled) sb.write(' useButtonStyle="true"');
  sb.write('>\n');

  sb.write('  <visual>\n');
  sb.write('    <binding template="ToastGeneric">\n');
  if (message.heroImage != null) {
    sb.write(
        '      <image placement="hero" src="${_escapeXml(message.heroImage!)}"/>\n');
  }
  if (message.title != null) {
    sb.write('      <text>${_escapeXml(message.title!)}</text>\n');
  }
  if (message.body != null) {
    sb.write('      <text>${_escapeXml(message.body!)}</text>\n');
  }
  for (final t in message.extraTexts) {
    sb.write('      ${_textTag(t)}\n');
  }
  if (message.image != null) {
    sb.write(
        '      <image placement="appLogoOverride" hint-crop="circle" src="${_escapeXml(message.image!)}"/>\n');
  }
  if (message.largeImage != null) {
    sb.write('      <image src="${_escapeXml(message.largeImage!)}"/>\n');
  }
  if (message.progress != null) {
    final p = message.progress!;
    sb.write('      <progress');
    if (p.title != null) {
      sb.write(' title="${_escapeXml(p.title!)}"');
    }
    final progressValue = p.value == null
        ? 'indeterminate'
        : p.value!.clamp(0.0, 1.0).toString();
    sb.write(' value="$progressValue"');
    if (p.valueStringOverride != null) {
      sb.write(
          ' valueStringOverride="${_escapeXml(p.valueStringOverride!)}"');
    }
    sb.write(' status="${_escapeXml(p.status)}"');
    sb.write('/>\n');
  }
  if (message.attribution != null) {
    sb.write(
        '      <text placement="attribution">${_escapeXml(message.attribution!)}</text>\n');
  }
  sb.write('    </binding>\n');
  sb.write('  </visual>\n');

  if (message.audio != null) {
    final a = message.audio!;
    if (a.silent) {
      sb.write('  <audio silent="true"/>\n');
    } else if (a.sourceUri != null) {
      sb.write('  <audio src="${_escapeXml(a.sourceUri!)}"');
      if (a.loop) sb.write(' loop="true"');
      sb.write('/>\n');
    }
  }

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
      if (a.contextMenu) {
        sb.write(' placement="contextMenu"');
      }
      sb.write('/>\n');
    }
    sb.write('  </actions>\n');
  }
  sb.write('</toast>\n');
  return sb.toString();
}
