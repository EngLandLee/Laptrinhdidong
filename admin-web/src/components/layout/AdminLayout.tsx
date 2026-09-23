import { Outlet } from 'react-router-dom';
import { Topbar } from './Topbar';
import { Sidebar } from './Sidebar';

export function AdminLayout() {
  return (
    <div className="min-h-screen flex bg-slate-50/70 dark:bg-[#0B0F19] bg-ambient-mesh text-slate-900 dark:text-slate-100 antialiased transition-colors duration-200">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <Topbar />
        <main className="flex-1 p-4 md:p-6 lg:p-8 overflow-y-auto">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

export default AdminLayout;
