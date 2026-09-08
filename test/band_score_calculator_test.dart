import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_prep_app/features/reading/services/band_score_calculator.dart';

void main() {
  group('BandScoreCalculator Tests', () {
    test('Official Cambridge rawToBand conversion', () {
      expect(BandScoreCalculator.rawToBand(40), 9.0);
      expect(BandScoreCalculator.rawToBand(39), 9.0);
      expect(BandScoreCalculator.rawToBand(38), 8.5);
      expect(BandScoreCalculator.rawToBand(37), 8.5);
      expect(BandScoreCalculator.rawToBand(36), 8.0);
      expect(BandScoreCalculator.rawToBand(35), 8.0);
      expect(BandScoreCalculator.rawToBand(34), 7.5);
      expect(BandScoreCalculator.rawToBand(33), 7.5);
      expect(BandScoreCalculator.rawToBand(32), 7.0);
      expect(BandScoreCalculator.rawToBand(30), 7.0);
      expect(BandScoreCalculator.rawToBand(29), 6.5);
      expect(BandScoreCalculator.rawToBand(27), 6.5);
      expect(BandScoreCalculator.rawToBand(26), 6.0);
      expect(BandScoreCalculator.rawToBand(23), 6.0);
      expect(BandScoreCalculator.rawToBand(22), 5.5);
      expect(BandScoreCalculator.rawToBand(19), 5.5);
      expect(BandScoreCalculator.rawToBand(18), 5.0);
      expect(BandScoreCalculator.rawToBand(15), 5.0);
      expect(BandScoreCalculator.rawToBand(14), 4.5);
      expect(BandScoreCalculator.rawToBand(13), 4.5);
      expect(BandScoreCalculator.rawToBand(12), 4.0);
      expect(BandScoreCalculator.rawToBand(10), 4.0);
      expect(BandScoreCalculator.rawToBand(9), 3.5);
      expect(BandScoreCalculator.rawToBand(8), 3.5);
      expect(BandScoreCalculator.rawToBand(7), 3.0);
      expect(BandScoreCalculator.rawToBand(5), 2.5);
      expect(BandScoreCalculator.rawToBand(3), 2.0);
      expect(BandScoreCalculator.rawToBand(0), 2.0);
    });

    test('Mini-test scaling for 13 questions', () {
      // 10 / 13 -> 10/13 * 40 = 30.77 -> 31 -> Band 7.0
      final res10 = BandScoreCalculator.calculateMiniTest(10, 13);
      expect(res10.scaledRaw, 31);
      expect(res10.bandScore, 7.0);
      expect(res10.bandRange, '6.5 - 7.5');

      // 13 / 13 -> 40 -> Band 9.0
      final res13 = BandScoreCalculator.calculateMiniTest(13, 13);
      expect(res13.scaledRaw, 40);
      expect(res13.bandScore, 9.0);
      expect(res13.bandRange, '8.5 - 9.0');

      // 0 / 13 -> 0 -> Band 2.0
      final res0 = BandScoreCalculator.calculateMiniTest(0, 13);
      expect(res0.scaledRaw, 0);
      expect(res0.bandScore, 2.0);
      expect(res0.bandRange, '2.0 - 2.5');

      // 12 / 13 -> 12/13 * 40 = 36.92 -> 37 -> Band 8.5
      final res12 = BandScoreCalculator.calculateMiniTest(12, 13);
      expect(res12.scaledRaw, 37);
      expect(res12.bandScore, 8.5);
      expect(res12.bandRange, '8.0 - 9.0');
    });

    test('Zero total questions edge case', () {
      final res = BandScoreCalculator.calculateMiniTest(0, 0);
      expect(res.bandScore, 2.0);
      expect(res.percentage, 0.0);
    });
  });
}
