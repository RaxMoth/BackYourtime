import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unspend/core/constants/strings.dart';
import 'package:unspend/core/theme/design_tokens.dart';
import '../../domain/entities/blocker_profile.dart';
import '../providers/profiles_provider.dart';
import 'section_widgets.dart';

class TaskListSection extends ConsumerStatefulWidget {
  final BlockerProfile profile;
  final Color accent;
  const TaskListSection({
    super.key,
    required this.profile,
    required this.accent,
  });

  @override
  ConsumerState<TaskListSection> createState() => _TaskListSectionState();
}

class _TaskListSectionState extends ConsumerState<TaskListSection> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    ref.read(profilesProvider.notifier).addTask(widget.profile.id, title);
    _taskController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.profile.tasks;
    final doneCount = tasks.where((t) => t.isDone).length;
    final isActive = widget.profile.isActive;

    return Semantics(
      label:
          '${S.current.tasks}, $doneCount ${S.current.tasks.toLowerCase()} of ${tasks.length} completed',
      child: SectionCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Icon(Icons.checklist_rounded,
                      color: widget.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      S.current.tasks,
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (tasks.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: doneCount == tasks.length
                            ? Colors.green.withValues(alpha: 0.15)
                            : widget.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$doneCount / ${tasks.length}',
                        style: TextStyle(
                          color: doneCount == tasks.length
                              ? Colors.green
                              : widget.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (tasks.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : doneCount / tasks.length,
                    backgroundColor: kBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      doneCount == tasks.length
                          ? Colors.green
                          : widget.accent,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Task items
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Semantics(
                        label:
                            '${task.title}, ${task.isDone ? S.current.allTasksDoneNote : S.current.tasks}',
                        checked: task.isDone,
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(profilesProvider.notifier)
                                .toggleTask(widget.profile.id, task.id);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: task.isDone
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: task.isDone
                                    ? Colors.green
                                    : kBorder,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: task.isDone
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.green,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: task.isDone
                                ? kTextSecondary
                                : kTextPrimary,
                            fontSize: 14,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: kTextSecondary,
                          ),
                        ),
                      ),
                      if (!isActive)
                        GestureDetector(
                          onTap: () => ref
                              .read(profilesProvider.notifier)
                              .removeTask(widget.profile.id, task.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              color: kTextSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Add-task row (only when shield is NOT active)
              if (!isActive) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _taskController,
                        style: TextStyle(color: kTextPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: S.current.addTaskHint,
                          hintStyle: TextStyle(
                            color: kTextSecondary,
                            fontSize: 14,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: kBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: kBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: kBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: widget.accent),
                          ),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _addTask,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: widget.accent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Info note when active
              if (isActive && tasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: kTextSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        doneCount == tasks.length
                            ? S.current.allTasksDoneNote
                            : S.current.tasksRemainingNote(
                                tasks.length - doneCount,
                              ),
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    S.current.emptyTasksHint,
                    style: TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
