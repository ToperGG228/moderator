import { prisma } from '../../../lib/prisma';
import { UserRole } from '../../../lib/types';
import { updateUserRole } from '../actions';

export const dynamic = 'force-dynamic';

async function getUsers() {
  return prisma.user.findMany({
    include: {
      orders: true
    },
    orderBy: { createdAt: 'desc' }
  });
}

const roleLabels: Record<UserRole, string> = {
  ADMIN: 'Администратор',
  CUSTOMER: 'Покупатель'
};

export default async function AdminUsersPage() {
  const users = await getUsers();
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Пользователи</h1>
        <p className="text-sm text-slate-600">Назначайте роли и проверяйте активность покупателей.</p>
      </div>
      <div className="overflow-x-auto rounded-xl border border-orange-100 bg-white">
        <table className="w-full text-left text-sm">
          <thead className="bg-orange-50 text-slate-700">
            <tr>
              <th className="px-4 py-3">Пользователь</th>
              <th className="px-4 py-3">Заказы</th>
              <th className="px-4 py-3">Роль</th>
              <th className="px-4 py-3">Дата регистрации</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="border-t">
                <td className="px-4 py-3">
                  <div className="font-medium text-slate-900">{user.name ?? 'Без имени'}</div>
                  <div className="text-xs text-slate-500">{user.email}</div>
                </td>
                <td className="px-4 py-3">{user.orders.length}</td>
                <td className="px-4 py-3">
                  <form action={updateUserRole} className="flex items-center gap-2 text-xs">
                    <input type="hidden" name="userId" value={user.id} />
                    <select name="role" defaultValue={user.role} className="rounded-md border px-2 py-1 text-xs">
                      {Object.values(UserRole).map((role) => (
                        <option key={role} value={role}>
                          {roleLabels[role]}
                        </option>
                      ))}
                    </select>
                    <button type="submit" className="rounded-md border border-brand px-2 py-1 text-brand">
                      Сохранить
                    </button>
                  </form>
                </td>
                <td className="px-4 py-3 text-slate-600">
                  {new Date(user.createdAt).toLocaleDateString('ru-RU')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <div className="p-6 text-sm text-slate-600">Пользователи не найдены.</div>
        )}
      </div>
    </div>
  );
}
