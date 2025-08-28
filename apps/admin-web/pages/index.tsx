import type { NextPage } from 'next';
import React, { useState } from 'react';

// TODO:
// import { createClient } from '@supabase/supabase-js';
// const supabase = createClient('YOUR_SUPABASE_URL', 'YOUR_SUPABASE_SERVICE_ROLE_KEY');

// --- MOCK DATA ---
const mockBuses = [
  { id: 'bus_1', plate: 'ح ب أ-1234', driver: 'أبو فهد', lat: 24.7200, lng: 46.6820, status: 'in_progress' },
  { id: 'bus_2', plate: 'ر ق م-5678', driver: 'سعيد', lat: 24.7100, lng: 46.6700, status: 'scheduled' },
];

const mockUsers = [
    { id: 'user_1', name: 'أبو فهد', role: 'driver' },
    { id: 'user_2', name: 'أم ليان ومازن', role: 'parent' },
];

const mockReport = [
    { student: 'ليان الزهراني', status: 'picked_up', time: '06:31 AM' },
    { student: 'مازن الزهراني', status: 'absent', time: '06:45 AM' },
];

const mockInvitations = [
    { id: 'inv_1', email: 'parent@test.com', role: 'parent', status: 'pending', expires_at: '2023-10-05' },
    { id: 'inv_2', email: 'driver@test.com', role: 'driver', status: 'pending', expires_at: '2023-10-06' },
    { id: 'inv_3', email: 'old@test.com', role: 'parent', status: 'accepted', expires_at: '2023-09-01' },
];

const mockAssignments = [
    { bus_plate: 'ح ب أ-1234', driver: 'أبو فهد', supervisor: 'مشرف ١' },
    { bus_plate: 'ن ق ل-9876', driver: 'N/A', supervisor: 'N/A' },
]


// --- COMPONENTS ---
const CrudTable = ({ title, data, actions }: { title: string, data: any[], actions?: any }) => (
    <div>
        <h3>{title}</h3>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
                <tr>
                    {data.length > 0 && Object.keys(data[0]).map(key => <th key={key} style={{ border: '1px solid #ddd', padding: '8px', textAlign: 'left' }}>{key}</th>)}
                    {actions && <th>Actions</th>}
                </tr>
            </thead>
            <tbody>
                {data.map((row: any) => (
                    <tr key={row.id}>
                        {Object.keys(row).map((key) => <td key={key} style={{ border: '1px solid #ddd', padding: '8px' }}>{row[key]}</td>)}
                        {actions && <td style={{ border: '1px solid #ddd', padding: '8px' }}>{actions(row)}</td>}
                    </tr>
                ))}
            </tbody>
        </table>
        <button style={{ marginTop: '1rem' }}>+ Invite New User</button>
    </div>
);

const InvitationsDashboard = () => {
    const actions = (row: any) => (
        row.status === 'pending' ? <button style={{ color: 'red' }}>Revoke</button> : null
    );
    return <CrudTable title="User Invitations" data={mockInvitations} actions={actions} />;
};

const AssignmentsDashboard = () => {
     const actions = (row: any) => (
        <>
            <button>Assign Driver</button>
            <button>Assign Supervisor</button>
        </>
    );
    return <CrudTable title="Bus Assignments" data={mockAssignments} actions={actions} />;
};


const AdminPage: NextPage = () => {
  const [activeView, setActiveView] = useState('invitations');

  const renderView = () => {
    switch (activeView) {
      case 'invitations':
        return <InvitationsDashboard />;
      case 'assignments':
        return <AssignmentsDashboard />;
      case 'users':
        return <CrudTable title="Manage Users" data={mockUsers} />;
      case 'routes':
        return <p>CRUD for Routes and Stops placeholder.</p>;
      default:
        return <InvitationsDashboard />;
    }
  };

  return (
    <div style={{ display: 'flex', fontFamily: 'sans-serif' }}>
      <aside style={{ width: '220px', background: '#f4f4f4', padding: '1rem', height: '100vh' }}>
        <h2>Admin Dashboard</h2>
        <nav>
          <ul style={{ listStyle: 'none', padding: 0 }}>
            <li style={{ marginBottom: '10px' }}><button onClick={() => setActiveView('invitations')}>Invitations</button></li>
            <li style={{ marginBottom: '10px' }}><button onClick={() => setActiveView('assignments')}>Bus Assignments</button></li>
            <li style={{ marginBottom: '10px' }}><button onClick={() => setActiveView('routes')}>Manage Routes</button></li>
            <li style={{ marginBottom: '10px' }}><button onClick={() => setActiveView('users')}>Manage Users</button></li>
          </ul>
        </nav>
      </aside>
      <main style={{ flex: 1, padding: '2rem' }}>
        <h1>School Bus Management</h1>
        {renderView()}
      </main>
    </div>
  );
};

export default AdminPage;
