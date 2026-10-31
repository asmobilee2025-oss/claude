import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators.dart';
import '../../models/category.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final repo = ref.read(catalogRepoProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(t.addCategory),
      ),
      body: AsyncBody(
        value: ref.watch(categoriesProvider),
        data: (cats) {
          if (cats.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: t.noCategories,
              subtitle: t.seedCategoriesHint,
              action: FilledButton.icon(
                onPressed: () async {
                  await repo.seedDefaultCategories();
                  if (context.mounted) context.toast(t.saved);
                },
                icon: const Icon(Icons.auto_awesome),
                label: Text(t.loadDefaultCategories),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: cats.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = cats[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: context.colors.primaryContainer, child: Icon(c.iconData, color: context.colors.primary)),
                  title: Text('${c.nameEn}  ·  ${c.nameAr}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('id: ${c.id} · ${t.order}: ${c.order}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(
                      value: c.active,
                      onChanged: (v) => repo.saveCategory(Category(id: c.id, nameEn: c.nameEn, nameAr: c.nameAr, icon: c.icon, order: c.order, active: v)),
                    ),
                    IconButton(tooltip: t.edit, onPressed: () => _edit(context, ref, c), icon: const Icon(Icons.edit_outlined)),
                    IconButton(
                      tooltip: t.delete,
                      onPressed: () async {
                        if (await confirmDialog(context, title: t.deleteCategory, message: t.deleteCategoryConfirm, danger: true, confirm: t.delete)) {
                          await repo.deleteCategory(c.id);
                        }
                      },
                      icon: Icon(Icons.delete_outline, color: context.colors.error),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category? c) async {
    final result = await showDialog<Category>(context: context, builder: (_) => _CategoryDialog(existing: c));
    if (result == null) return;
    try {
      await ref.read(catalogRepoProvider).saveCategory(result);
      if (context.mounted) context.toast(context.t.saved);
    } catch (_) {
      if (context.mounted) context.toast(context.t.somethingWentWrong, error: true);
    }
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.existing});
  final Category? existing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _id = TextEditingController(text: widget.existing?.id ?? '');
  late final _en = TextEditingController(text: widget.existing?.nameEn ?? '');
  late final _ar = TextEditingController(text: widget.existing?.nameAr ?? '');
  late final _order = TextEditingController(text: '${widget.existing?.order ?? 0}');
  late String _icon = widget.existing?.icon ?? 'category';

  @override
  void dispose() {
    for (final c in [_id, _en, _ar, _order]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final v = Validators(t);
    final editing = widget.existing != null;
    return AlertDialog(
      title: Text(editing ? t.editCategory : t.addCategory),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _id,
                enabled: !editing,
                decoration: InputDecoration(labelText: t.categoryId, helperText: 'e.g. mobiles'),
                validator: (s) => RegExp(r'^[a-z0-9-]{2,40}$').hasMatch(s ?? '') ? null : t.invalidSlug,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _en, decoration: InputDecoration(labelText: t.nameEnglish), validator: (s) => v.length(s, max: 40)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ar,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(labelText: t.nameArabic),
                validator: (s) => v.length(s, max: 40),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.order),
                validator: (s) => int.tryParse(s ?? '') == null ? t.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              Align(alignment: AlignmentDirectional.centerStart, child: Text(t.icon)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final e in categoryIcons.entries)
                  ChoiceChip(
                    label: Icon(e.value, size: 20),
                    selected: _icon == e.key,
                    onSelected: (_) => setState(() => _icon = e.key),
                  ),
              ]),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            Navigator.pop(
              context,
              Category(
                id: _id.text.trim(),
                nameEn: _en.text.trim(),
                nameAr: _ar.text.trim(),
                icon: _icon,
                order: int.parse(_order.text.trim()),
                active: widget.existing?.active ?? true,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
