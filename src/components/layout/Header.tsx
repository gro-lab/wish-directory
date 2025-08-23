// src/components/layout/Header.tsx
import Link from 'next/link'
import { Menu, Search, User } from 'lucide-react'

export default function Header() {
  return (
    <header className="sticky top-0 z-50 bg-white/90 backdrop-blur-md border-b border-gray-200">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-gradient-to-br from-indigo-600 to-purple-500 rounded-lg" />
            <span className="font-bold text-xl">Wish Directory</span>
          </Link>

          {/* Navigation */}
          <nav className="hidden md:flex items-center space-x-8">
            <Link href="/explore" className="text-gray-700 hover:text-indigo-600 transition">
              Explore
            </Link>
            <Link href="/categories" className="text-gray-700 hover:text-indigo-600 transition">
              Categories
            </Link>
            <Link href="/about" className="text-gray-700 hover:text-indigo-600 transition">
              About
            </Link>
          </nav>

          {/* Actions */}
          <div className="flex items-center space-x-4">
            <button className="p-2 hover:bg-gray-100 rounded-lg transition">
              <Search className="w-5 h-5 text-gray-600" />
            </button>
            <button className="hidden md:flex items-center space-x-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition">
              <User className="w-4 h-4" />
              <span>Sign Up</span>
            </button>
            <button className="md:hidden p-2 hover:bg-gray-100 rounded-lg transition">
              <Menu className="w-5 h-5 text-gray-600" />
            </button>
          </div>
        </div>
      </div>
    </header>
  )
}