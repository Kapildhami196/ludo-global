import 'dart:collection';

class DiceWeights {
  DiceWeights._(List<double> values)
      : _values = List<double>.unmodifiable(values) {
    if (_values.length != 6) {
      throw ArgumentError(
        'DiceWeights requires exactly six face weights.',
      );
    }

    if (_values.any((double value) => value < 0)) {
      throw ArgumentError('Dice weights cannot be negative.');
    }
  }

  factory DiceWeights.fair({
    double baseWeight = 100,
  }) {
    if (baseWeight <= 0) {
      throw ArgumentError.value(
        baseWeight,
        'baseWeight',
        'Base weight must be greater than zero.',
      );
    }

    return DiceWeights._(
      List<double>.filled(6, baseWeight),
    );
  }

  factory DiceWeights.fromValues(List<double> values) {
    return DiceWeights._(List<double>.of(values));
  }

  final List<double> _values;

  UnmodifiableListView<double> get values =>
      UnmodifiableListView<double>(_values);

  double get totalWeight =>
      _values.fold<double>(0, (sum, value) => sum + value);

  double weightFor(int face) {
    _requireFace(face);
    return _values[face - 1];
  }

  double probabilityFor(int face) {
    _requireFace(face);

    final double total = totalWeight;
    if (total <= 0) {
      throw StateError(
        'At least one dice face must have a positive weight.',
      );
    }

    return weightFor(face) / total;
  }

  DiceWeights withAddedWeight(
    int face,
    double amount,
  ) {
    _requireFace(face);

    final double updated = weightFor(face) + amount;
    if (updated < 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Weight adjustment cannot make a face negative.',
      );
    }

    final List<double> next = List<double>.of(_values);
    next[face - 1] = updated;
    return DiceWeights._(next);
  }

  DiceWeights cappedAtProbability(double maxProbability) {
    if (maxProbability <= 0 || maxProbability >= 1) {
      throw ArgumentError.value(
        maxProbability,
        'maxProbability',
        'Maximum probability must be greater than 0 and less than 1.',
      );
    }

    if (maxProbability < 1 / 6) {
      throw ArgumentError.value(
        maxProbability,
        'maxProbability',
        'A six-sided die cannot cap every face below 1/6.',
      );
    }

    final List<double> next = List<double>.of(_values);

    for (int iteration = 0; iteration < 6; iteration++) {
      final double total =
          next.fold<double>(0, (sum, value) => sum + value);
      if (total <= 0) {
        throw StateError(
          'At least one dice face must have a positive weight.',
        );
      }

      int? faceToCap;
      for (int index = 0; index < next.length; index++) {
        if (next[index] / total > maxProbability) {
          faceToCap = index;
          break;
        }
      }

      if (faceToCap == null) {
        break;
      }

      final double otherWeight = total - next[faceToCap];
      if (otherWeight <= 0) {
        throw StateError(
          'Cannot cap probability when all other face weights are zero.',
        );
      }

      next[faceToCap] =
          (maxProbability / (1 - maxProbability)) * otherWeight;
    }

    return DiceWeights._(next);
  }

  DiceWeights withWeight(
    int face,
    double value,
  ) {
    _requireFace(face);

    if (value < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'Dice weight cannot be negative.',
      );
    }

    final List<double> next = List<double>.of(_values);
    next[face - 1] = value;
    return DiceWeights._(next);
  }

  void _requireFace(int face) {
    if (face < 1 || face > 6) {
      throw ArgumentError.value(
        face,
        'face',
        'Dice face must be from 1 through 6.',
      );
    }
  }
}
