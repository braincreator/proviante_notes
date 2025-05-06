// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:shared_preferences/shared_preferences.dart' as _i8;

import 'core/di/register_module.dart' as _i11;
import 'core/theme/bloc/theme_bloc.dart' as _i9;
import 'data/datasources/isar_note_datasource.dart' as _i4;
import 'data/datasources/local_note_datasource.dart' as _i3;
import 'data/repositories/note_repository_impl.dart' as _i6;
import 'domain/repositories/note_repository.dart' as _i5;
import 'presentation/note_edit/bloc/note_edit_bloc.dart' as _i10;
import 'presentation/notes_list/bloc/notes_list_bloc.dart' as _i7;

// initializes the registration of main-scope dependencies inside of GetIt
Future<_i1.GetIt> $initGetIt(
  _i1.GetIt getIt, {
  String? environment,
  _i2.EnvironmentFilter? environmentFilter,
}) async {
  final gh = _i2.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final registerModule = _$RegisterModule();
  gh.singleton<_i3.LocalNoteDatasource>(() => _i4.IsarNoteDatasource());
  gh.lazySingleton<_i5.NoteRepository>(
      () => _i6.NoteRepositoryImpl(datasource: gh<_i3.LocalNoteDatasource>()));
  gh.lazySingleton<_i7.NotesListBloc>(
      () => _i7.NotesListBloc(noteRepository: gh<_i5.NoteRepository>()));
  await gh.singletonAsync<_i8.SharedPreferences>(
    () => registerModule.prefs,
    preResolve: true,
  );
  gh.singleton<_i9.ThemeBloc>(() => _i9.ThemeBloc(gh<_i8.SharedPreferences>()));
  gh.factory<_i10.NoteEditBloc>(
      () => _i10.NoteEditBloc(noteRepository: gh<_i5.NoteRepository>()));
  return getIt;
}

class _$RegisterModule extends _i11.RegisterModule {}
