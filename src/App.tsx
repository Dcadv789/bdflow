import React from 'react';
import { User, Bell, Search, Menu, BarChart3, Users, Calendar, Settings } from 'lucide-react';

function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Topbar */}
      <header className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            {/* Logo e título */}
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                  <BarChart3 className="w-5 h-5 text-white" />
                </div>
                <h1 className="text-xl font-semibold text-gray-900">CRM Pro</h1>
              </div>
            </div>

            {/* Navegação central */}
            <nav className="hidden md:flex items-center space-x-8">
              <a href="#" className="flex items-center space-x-2 text-blue-600 hover:text-blue-700 transition-colors">
                <BarChart3 className="w-4 h-4" />
                <span className="text-sm font-medium">Dashboard</span>
              </a>
              <a href="#" className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors">
                <Users className="w-4 h-4" />
                <span className="text-sm font-medium">Clientes</span>
              </a>
              <a href="#" className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors">
                <Calendar className="w-4 h-4" />
                <span className="text-sm font-medium">Tarefas</span>
              </a>
              <a href="#" className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors">
                <Settings className="w-4 h-4" />
                <span className="text-sm font-medium">Configurações</span>
              </a>
            </nav>

            {/* Área direita com busca e usuário */}
            <div className="flex items-center space-x-4">
              {/* Busca */}
              <div className="hidden sm:block relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Search className="h-4 w-4 text-gray-400" />
                </div>
                <input
                  type="text"
                  placeholder="Buscar..."
                  className="block w-64 pl-10 pr-3 py-2 border border-gray-300 rounded-lg text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {/* Notificações */}
              <button className="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors">
                <Bell className="w-5 h-5" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>

              {/* Menu do usuário */}
              <div className="flex items-center space-x-3">
                <div className="hidden sm:block text-right">
                  <p className="text-sm font-medium text-gray-900">João Silva</p>
                  <p className="text-xs text-gray-600">Administrador</p>
                </div>
                <button className="flex items-center space-x-1 p-1 rounded-lg hover:bg-gray-100 transition-colors">
                  <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                    <User className="w-4 h-4 text-white" />
                  </div>
                </button>
              </div>

              {/* Menu mobile */}
              <button className="md:hidden p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg transition-colors">
                <Menu className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Conteúdo principal */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="text-center">
          <div className="max-w-md mx-auto">
            <div className="w-24 h-24 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-6">
              <BarChart3 className="w-12 h-12 text-blue-600" />
            </div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">
              Bem-vindo ao CRM Pro
            </h2>
            <p className="text-gray-600 mb-8">
              Sua plataforma de gestão de relacionamento com clientes e tarefas está pronta para ser configurada.
            </p>
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                Próximos Passos
              </h3>
              <div className="space-y-2 text-left">
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-blue-600 rounded-full"></div>
                  <span className="text-sm text-gray-700">Configurar banco de dados</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-gray-300 rounded-full"></div>
                  <span className="text-sm text-gray-500">Criar migrations</span>
                </div>
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-gray-300 rounded-full"></div>
                  <span className="text-sm text-gray-500">Implementar funcionalidades</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;