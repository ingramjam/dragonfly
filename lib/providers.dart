import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final uuidProvider = Provider((_) => const Uuid());
