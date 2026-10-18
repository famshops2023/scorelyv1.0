import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final soundDir = Directory('assets/sounds');
  if (!soundDir.existsSync()) {
    soundDir.createSync(recursive: true);
  }

  // 1. Boundary Four: snappy wooden strike followed by quick rising cheer tone
  generateWavFile(
    File('assets/sounds/boundary_four.wav'),
    durationSeconds: 0.55,
    sampleRate: 44100,
    generator: (t, total) {
      // Impact crack (0 to 0.08s): low frequency impact + sharp noise burst
      double impact = 0.0;
      if (t < 0.08) {
        final decay = exp(-t * 60.0);
        impact = sin(2 * pi * 180 * t) * decay * 0.7 +
            (Random((t * 10000).toInt()).nextDouble() * 2 - 1) * decay * 0.5;
      }
      // Rising fanfare tone (0.05s to 0.55s)
      double tone = 0.0;
      if (t >= 0.05) {
        final toneTime = t - 0.05;
        final freq = 440.0 + (toneTime * 300.0); // 440Hz -> 590Hz
        final env = sin(pi * (t / total));
        tone = (sin(2 * pi * freq * t) * 0.4 + sin(2 * pi * freq * 1.5 * t) * 0.2) * env;
      }
      return (impact + tone).clamp(-1.0, 1.0);
    },
  );

  // 2. Boundary Six: thunderous crack with ascending celebratory chord
  generateWavFile(
    File('assets/sounds/boundary_six.wav'),
    durationSeconds: 0.9,
    sampleRate: 44100,
    generator: (t, total) {
      // Big impact
      double impact = 0.0;
      if (t < 0.12) {
        final decay = exp(-t * 40.0);
        impact = sin(2 * pi * 140 * t) * decay * 0.8 +
            (Random((t * 10000).toInt()).nextDouble() * 2 - 1) * decay * 0.6;
      }
      // Celebratory chord: Major triad (C5=523, E5=659, G5=784, C6=1046)
      double chord = 0.0;
      if (t >= 0.08) {
        final chordTime = t - 0.08;
        final env = exp(-chordTime * 2.5);
        chord = (sin(2 * pi * 523.25 * t) * 0.3 +
                sin(2 * pi * 659.25 * t) * 0.25 +
                sin(2 * pi * 783.99 * t) * 0.25 +
                sin(2 * pi * 1046.50 * t) * 0.2) *
            env;
      }
      return (impact + chord).clamp(-1.0, 1.0);
    },
  );

  // 3. Wicket: sharp stump timber strike + whistle / buzzer drop
  generateWavFile(
    File('assets/sounds/wicket.wav'),
    durationSeconds: 0.75,
    sampleRate: 44100,
    generator: (t, total) {
      // Wood crack / timber hit
      double crack = 0.0;
      if (t < 0.15) {
        final decay = exp(-t * 50.0);
        crack = sin(2 * pi * 320 * t) * decay * 0.6 +
            sin(2 * pi * 850 * t) * decay * 0.4 +
            (Random((t * 20000).toInt()).nextDouble() * 2 - 1) * decay * 0.5;
      }
      // Dramatic descending alert tone
      double dropTone = 0.0;
      if (t >= 0.05) {
        final dt = t - 0.05;
        final freq = max(180.0, 700.0 - (dt * 750.0));
        final env = exp(-dt * 3.5);
        dropTone = sin(2 * pi * freq * t) * 0.5 * env;
      }
      return (crack + dropTone).clamp(-1.0, 1.0);
    },
  );

  // 4. Match Victory: triumphant ascending 3-note celebration
  generateWavFile(
    File('assets/sounds/match_victory.wav'),
    durationSeconds: 1.2,
    sampleRate: 44100,
    generator: (t, total) {
      // 3 notes: G4 (392Hz, 0-0.3s), C5 (523Hz, 0.3-0.6s), E5/G5 chord (0.6-1.2s)
      double note = 0.0;
      if (t < 0.28) {
        final env = sin(pi * (t / 0.28));
        note = sin(2 * pi * 392.00 * t) * 0.5 * env;
      } else if (t < 0.58) {
        final env = sin(pi * ((t - 0.3) / 0.28));
        note = sin(2 * pi * 523.25 * t) * 0.55 * env;
      } else {
        final ct = t - 0.6;
        final env = exp(-ct * 2.2);
        note = (sin(2 * pi * 659.25 * t) * 0.35 +
                sin(2 * pi * 783.99 * t) * 0.35 +
                sin(2 * pi * 1046.50 * t) * 0.25) *
            env;
      }
      return note.clamp(-1.0, 1.0);
    },
  );

  // ignore: avoid_print
  print('Successfully generated 4 sound files in assets/sounds/');
}

void generateWavFile(
  File file, {
  required double durationSeconds,
  required int sampleRate,
  required double Function(double t, double total) generator,
}) {
  final numSamples = (durationSeconds * sampleRate).toInt();
  final numChannels = 1; // mono
  final bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final subChunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
  final chunkSize = 36 + subChunk2Size;

  final byteData = ByteData(44 + subChunk2Size);

  // RIFF header
  byteData.setUint8(0, 0x52); // 'R'
  byteData.setUint8(1, 0x49); // 'I'
  byteData.setUint8(2, 0x46); // 'F'
  byteData.setUint8(3, 0x46); // 'F'
  byteData.setUint32(4, chunkSize, Endian.little);
  byteData.setUint8(8, 0x57);  // 'W'
  byteData.setUint8(9, 0x41);  // 'A'
  byteData.setUint8(10, 0x56); // 'V'
  byteData.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  byteData.setUint8(12, 0x66); // 'f'
  byteData.setUint8(13, 0x6D); // 'm'
  byteData.setUint8(14, 0x74); // 't'
  byteData.setUint8(15, 0x20); // ' '
  byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
  byteData.setUint16(22, numChannels, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, byteRate, Endian.little);
  byteData.setUint16(32, blockAlign, Endian.little);
  byteData.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk
  byteData.setUint8(36, 0x64); // 'd'
  byteData.setUint8(37, 0x61); // 'a'
  byteData.setUint8(38, 0x74); // 't'
  byteData.setUint8(39, 0x61); // 'a'
  byteData.setUint32(40, subChunk2Size, Endian.little);

  // samples
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final sample = generator(t, durationSeconds);
    final intSample = (sample * 32767.0).round().clamp(-32768, 32767);
    byteData.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}
