'use client';

import { useEffect } from 'react';
import { useFormState } from 'react-dom';
import { toast } from 'sonner';
import { createProduct, type ActionState } from '../actions';

type Category = { id: string; name: string };

const initialState: ActionState = { ok: false, message: '' };

export function ProductCreateForm({ categories }: { categories: Category[] }) {
  const [state, formAction] = useFormState(createProduct, initialState);

  useEffect(() => {
    if (!state.message) return;
    if (state.ok) {
      toast.success(state.message);
    } else {
      toast.error(state.message);
    }
  }, [state]);

  const fieldError = (field: ActionState['field']) =>
    state.field === field ? 'border-red-400 focus:border-red-400' : 'border-slate-200';

  return (
    <div className="rounded-xl border border-orange-100 bg-white p-4">
      <h2 className="text-sm font-semibold text-slate-700">Новый товар</h2>
      <form action={formAction} className="mt-4 grid gap-3 md:grid-cols-2">
        <div className="space-y-1">
          <input
            name="name"
            placeholder="Название"
            className={`rounded-md border px-3 py-2 text-sm ${fieldError('name')}`}
            required
          />
          {state.field === 'name' && (
            <p className="text-xs text-red-500">{state.message}</p>
          )}
        </div>
        <div className="space-y-1">
          <input
            name="slug"
            placeholder="Слаг (например, pelmeni-domashnie)"
            className={`rounded-md border px-3 py-2 text-sm ${fieldError('slug')}`}
            required
          />
          {state.field === 'slug' && (
            <p className="text-xs text-red-500">{state.message}</p>
          )}
        </div>
        <input
          name="price"
          type="number"
          min="0"
          placeholder="Цена"
          className={`rounded-md border px-3 py-2 text-sm ${fieldError('form')}`}
          required
        />
        <select
          name="categoryId"
          className="rounded-md border px-3 py-2 text-sm"
          defaultValue=""
        >
          <option value="">Без категории</option>
          {categories.map((category) => (
            <option key={category.id} value={category.id}>
              {category.name}
            </option>
          ))}
        </select>
        <input
          name="imageUrl"
          placeholder="URL фото"
          className="rounded-md border px-3 py-2 text-sm md:col-span-2"
        />
        <textarea
          name="description"
          placeholder="Описание товара"
          className={`min-h-[96px] rounded-md border px-3 py-2 text-sm md:col-span-2 ${fieldError('form')}`}
          required
        />
        {state.field === 'form' && (
          <p className="text-xs text-red-500 md:col-span-2">{state.message}</p>
        )}
        <button type="submit" className="rounded-md bg-brand px-3 py-2 text-sm text-white md:col-span-2">
          Добавить товар
        </button>
      </form>
    </div>
  );
}
