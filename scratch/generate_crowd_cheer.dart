import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final soundFile = File('assets/sounds/match_victory.wav');

  // Crowd cheer: 2.8 seconds duration
  generateCrowdCheer(soundFile, durationSeconds: 2.8, sampleRate: 44100);
  // ignore: avoid_print
  print('Successfully updated assets/sounds/match_victory.wav with crowd cheer sound!');
}

void generateCrowdCheer(File file, {required double durationSeconds, required int sampleRate}) {
  final numSamples = (durationSeconds * sampleRate).toInt();
  final random = Random(42);

  // Buffer for samples
  final samples = Float64List(numSamples);

  // 1. Generate dense applause clapping impulses (stadium clapping)
  // Around 350-450 random claps distributed over the duration
  final totalClaps = (durationSeconds * 220).toInt();
  for (int c = 0; c < totalClaps; c++) {
    // Claps build up from t=0.2s to t=2.5s
    final clapStartSample = (0.15 * sampleRate + random.nextDouble() * (durationSeconds - 0.5) * sampleRate).toInt();
    final clapDurationSamples = (sampleRate * 0.025).toInt(); // 25ms per hand clap
    final clapAmp = (0.2 + random.nextDouble() * 0.3);

    for (int j = 0; j < clapDurationSamples; j++) {
      final idx = clapStartSample + j;
      if (idx < numSamples) {
        final t = j / clapDurationSamples;
        final env = exp(-t * 22.0);
        final noise = (random.nextDouble() * 2 - 1);
        samples[idx] += noise * env * clapAmp;
      }
    }
  }

  // 2. Generate layered crowd vocal roar (multi-band filtered pink/brown noise with vocal formants)
  // Low-pass filtered noise state
  double roarLow = 0.0;
  double roarMid = 0.0;
  double roarHigh = 0.0;

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Overall crowd swell envelope:
    // Swells up from 0 to 0.6s, sustains from 0.6 to 2.0s, natural decay 2.0 to 2.8s
    double env;
    if (t < 0.6) {
      env = sin((t / 0.6) * (pi / 2));
    } else if (t < 2.0) {
      env = 1.0 - (t - 0.6) * 0.08; // slight variation
    } else {
      final decayT = (t - 2.0) / 0.8;
      env = (1.0 - 0.11) * exp(-decayT * 2.8);
    }

    // White noise source
    final white = (random.nextDouble() * 2 - 1);

    // Multi-band filters simulating vocal formant resonances (500Hz, 1200Hz, 2400Hz)
    roarLow = roarLow * 0.93 + white * 0.07;
    roarMid = roarMid * 0.82 + (white - roarLow) * 0.18;
    roarHigh = roarHigh * 0.68 + (white - roarMid) * 0.32;

    // Subtle wave modulation (crowd wave effect)
    final modulation = 1.0 + 0.18 * sin(2 * pi * 3.5 * t) + 0.12 * sin(2 * pi * 7.2 * t);

    final crowdRoar = (roarLow * 0.65 + roarMid * 0.55 + roarHigh * 0.35) * env * modulation * 1.8;
    samples[i] += crowdRoar;
  }

  // 3. Add stadium whistles (excited fan whistling)
  // Whistle 1: at t = 0.3s to 1.1s (rising pitch 2100Hz -> 2500Hz -> 2300Hz)
  final w1Start = (0.35 * sampleRate).toInt();
  final w1Length = (0.75 * sampleRate).toInt();
  for (int j = 0; j < w1Length; j++) {
    final idx = w1Start + j;
    if (idx < numSamples) {
      final wt = j / sampleRate;
      final env = sin(pi * (j / w1Length));
      final freq = 2200.0 + 350.0 * sin(pi * (j / w1Length)) + (random.nextDouble() * 20 - 10);
      final whistle = sin(2 * pi * freq * wt) * env * 0.22;
      samples[idx] += whistle;
    }
  }

  // Whistle 2: at t = 0.8s to 1.7s (trilling high whistle 2600Hz)
  final w2Start = (0.85 * sampleRate).toInt();
  final w2Length = (0.8 * sampleRate).toInt();
  for (int j = 0; j < w2Length; j++) {
    final idx = w2Start + j;
    if (idx < numSamples) {
      final wt = j / sampleRate;
      final env = sin(pi * (j / w2Length));
      final trill = sin(2 * pi * 18 * wt); // 18Hz vibrato
      final freq = 2650.0 + trill * 100.0;
      final whistle = sin(2 * pi * freq * wt) * env * 0.18;
      samples[idx] += whistle;
    }
  }

  // 4. Normalize and convert to 16-bit PCM WAV
  double maxAmp = 0.0;
  for (int i = 0; i < numSamples; i++) {
    final abs = samples[i].abs();
    if (abs > maxAmp) maxAmp = abs;
  }
  final normFactor = maxAmp > 0.0 ? (0.92 / maxAmp) : 1.0;

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
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little); // PCM
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

  // Write samples
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    final sample = (samples[i] * normFactor).clamp(-1.0, 1.0);
    final intSample = (sample * 32767.0).round().clamp(-32768, 32767);
    byteData.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}
