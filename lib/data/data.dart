/// Data module exports
/// Contains repository implementations, data sources, and models
library;

// Repositories
export 'repositories/auth_repository_impl.dart';
export 'repositories/user_repository_impl.dart';
export 'repositories/exercise_repository_impl.dart';
export 'repositories/chat_repository_impl.dart';

// Data sources
export 'datasources/firebase_datasource.dart';
export 'datasources/local_datasource.dart';

// Models (DTOs)
export 'models/user_model.dart';
export 'models/exercise_model.dart';
export 'models/message_model.dart';
