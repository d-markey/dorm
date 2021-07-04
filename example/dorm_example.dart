import 'package:dorm/dorm.dart';

import 'Status.dart';
import 'Tasks.dart';
import 'TasksDb.dart';

Future main() async {
  print('initializing InMemoryDatabase...');
  final db = TasksDb();
  await db.open();
  print('   database ready');

  db.dump();

  print('initializing status codes...');
  await initializeStatusCodes(db);

  print('creating a TODO task...');
  var taskId = await createTask(db, 'A task');
  print('   task created with id = $taskId');

  print('creating another TODO task...');
  taskId = await createTask(db, 'Another task');
  print('   task created with id = $taskId');

  db.dump();

  print('load task #$taskId...');
  final task = await loadTask(db, taskId);
  print('   task = $task');
  print('   task status = ${task.statusRef.entity ?? 'SHOULD NEVER HAPPEN'}');

  db.dump();

  print('updating the task with status PENDING and due tomorrow...');
  task.statusRef.key = 'PENDING';
  task.dueDate = DateTime.now().add(Duration(days: 1));
  await updateTasks(db, [ task ]);
  print('   task updated successfully');
  print('   task = $task');
  print('   task status = ${task.statusRef.entity ?? 'SHOULD BE NULL'}');

  db.dump();

  print('searching tasks without a due date...');
  var matchingTasks = await searchTasksWithoutDueDate(db);
  print('   found ${matchingTasks.length} tasks');
  for (var t in matchingTasks) {
    print('      task = $t');
  }

  db.dump();

  print('loading "DONE" status entity...');
  final done = await getStatus(db, 'DONE');
  print('   done = $done');

  print('updating the task with entity DONE...');
  task.statusRef.entity = done;
  await updateTasks(db, [ task ]);
  print('   task updated successfully');
  print('   task = $task');
  print('   task status = ${task.statusRef.entity ?? 'SHOULD NEVER HAPPEN'}');

  db.dump();

  print('searching tasks with label containing "OTHER" (case insensitive)...');
  matchingTasks = await searchTasksContaining(db, 'OTHER');
  print('   found ${matchingTasks.length} tasks');
  for (var t in matchingTasks) {
    print('      task = $t');
  }

  print('searching tasks with status TODO...');
  matchingTasks = await searchToDoTasks(db);
  print('   found ${matchingTasks.length} tasks');
  for (var t in matchingTasks) {
    print('      task = $t');
  }

  print('cancel TODO tasks with a new status...');
  final cancelled = Status()
    ..code = 'CANCELLED'
    ..label = 'Task is cancelled';
  for (var t in matchingTasks) {
    t.statusRef.entity = cancelled;
  }

  print('save tasks...');
  await updateTasks(db, matchingTasks);
  print('   saved ${matchingTasks.length} tasks');
  for (var t in matchingTasks) {
    print('      task = $t');
  }

  db.dump();
}

Future initializeStatusCodes(TasksDb db) {
  final done = Status()
    ..code = 'DONE'
    ..label = 'Task is completed';

  final todo = Status()
    ..code = 'TODO'
    ..label = 'Task has not started yet';

  final pending = Status()
    ..code = 'PENDING'
    ..label = 'Task is in progress';

  return db.execute((dataContext, transaction) {
    return dataContext.statusCodes.saveMany(transaction, [ done, todo, pending ]);
  });
}

Future<int> createTask(TasksDb db, String label) {
  final task = Task()
    ..label = label
    ..statusRef.key = 'TODO';

  return db.execute((dataContext, transaction) async {
    await dataContext.tasks.save(transaction, task);
    return task.key!;
  });
}

Future<Task> loadTask(TasksDb db, int taskId) {
  return db.execute((dataContext, transaction) async {
    return (await dataContext.tasks.loadByKey(transaction, taskId))!;
  });
}

Future<Iterable<Task>> searchTasksContaining(TasksDb db, String text) {
  return db.execute((dataContext, transaction) {
    return dataContext.tasks.loadMany(transaction, Task.model.label.toLower().contains(text));
  });
}

late final IDormExpression _nullDueDateFilter = Task.model.dueDate.isNull();

Future<Iterable<Task>> searchTasksWithoutDueDate(TasksDb db) {
  return db.execute((dataContext, transaction) {
    // lazy loading
    return dataContext.tasks.lazy().loadMany(transaction, _nullDueDateFilter);
  });
}

late final IDormExpression _toDoFilter = Task.model.status.equals('TODO');

Future<Iterable<Task>> searchToDoTasks(TasksDb db) {
  return db.execute((dataContext, transaction) {
    return dataContext.tasks.loadMany(transaction, _toDoFilter);
  });
}

Future updateTasks(TasksDb db, Iterable<Task> tasks) {
  return db.execute((dataContext, transaction) async {
    final existingStatusCodes = (await dataContext.statusCodes.loadMany(transaction)).toList();
    final newStatusCodes = <Status>[];
    for (var task in tasks) {
      if (task.statusRef.entity != null && !existingStatusCodes.contains(task.statusRef.key)) {
        newStatusCodes.add(task.statusRef.entity!);
      }
    }
    if (newStatusCodes.isNotEmpty) {
      await dataContext.statusCodes.saveMany(transaction, newStatusCodes);
    }
    return await dataContext.tasks.saveMany(transaction, tasks);
  });
}

Future<Status?> getStatus(TasksDb db, String code) {
  return db.execute((dataContext, transaction) {
    return dataContext.statusCodes.loadByKey(transaction, code);
  });
}
