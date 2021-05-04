import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:authentication_with_bloc/erp/DataModels/Masters/Godown/GodownDataModel.dart';
import 'package:authentication_with_bloc/erp/Database/core/MasterDBAbstract.dart';
import 'package:meta/meta.dart';

part 'godownmasterlist_event.dart';
part 'godownmasterlist_state.dart';

class GodownmasterlistBloc
    extends Bloc<GodownmasterlistEvent, GodownmasterlistState> {
  final MasterDBAbstract dbHelper;

  GodownmasterlistBloc(this.dbHelper) : super(GodownmasterlistInitial());
  @override
  GodownmasterlistState get initialState => GodownmasterlistInitial();

  @override
  Stream<GodownmasterlistState> mapEventToState(
    GodownmasterlistEvent event,
  ) async* {
    final currentState = state;
    if (event is LoadData && !_hasReachedMax(currentState)) {
      try {
        if (currentState is GodownmasterlistInitial) {
          final groups = await _fetchPosts(0, 20);
          yield ListLoaded(items: groups, hasReachedMax: false);
          return;
        } else {
          final groups = await _fetchPosts(0, 20);
          yield ListLoaded(items: groups, hasReachedMax: false);
          return;
        }
        // if (currentState is ListLoaded) {
        //   List<Map> dataValues =
        //       await _fetchPosts(currentState.items.length, 20);

        //   yield dataValues.isEmpty
        //       ? currentState.copyWith(hasReachedMax: true)
        //       : ListLoaded(
        //           items: currentState.items..addAll(dataValues),
        //           hasReachedMax: false,
        //         );
        // }
      } catch (_) {
        yield ListError();
      }
    }
    if (event is SearchEvent) {
      try {
        print('Filter with word from bloc : ${event.filter}');
        final groups = await _fetchPosts(0, 20, event.filter);
        yield ListLoaded(items: groups, hasReachedMax: false);
        return;
      } catch (_) {
        yield ListError();
      }
    }

    if (event is AddEntityEvent) {
      try {
        print('Newc : ${event.entity.ItemName}');
        final status = await dbHelper.upsertEntity(event.entity);
        // await InventoryGroupDBHelper().upsertInventoryGroup(event.group);
        yield (SaveGroup(status));
        return;
      } catch (_) {
        yield SaveError();
      }
    }

    if (event is FetchEntityEvent && (currentState is ListLoaded)) {
      try {
        print('Newc : ${event.id}');
        final entity = await dbHelper.getEntityByID(event.id);

        // print('Fetch Group : ${entity.ParentGroupId}');
        // await InventoryGroupDBHelper().upsertInventoryGroup(event.group);
        yield (EntityFetched(entity, currentState.items));
        return;
      } catch (_) {
        yield FetchError();
      }
    }

    if (event is CreateEntityEvent && (currentState is ListLoaded)) {
      try {
        print('Create New blank');
        final entity = new GodownDataModel();
        yield (EntityFetched(entity, currentState.items));
        return;
      } catch (_) {
        yield FetchError();
      }
    }
  }

  bool _hasReachedMax(GodownmasterlistState state) =>
      state is ListLoaded && state.hasReachedMax;

  Future<List<Map>> _fetchPosts(int startIndex, int limit,
      [String filter = ""]) async {
    return await dbHelper.getAllEntitiesAsList(startIndex, limit, filter);
    // return await InventoryGroupDBHelper().getAllGroups(filter);
  }
}