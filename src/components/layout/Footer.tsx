// src/components/layout/Footer.tsx
import Link from 'next/link'
import { Github, Twitter, Linkedin } from 'lucide-react'

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="col-span-1 md:col-span-2">
            <div className="flex items-center space-x-2 mb-4">
              <div className="w-8 h-8 bg-gradient-to-br from-indigo-600 to-purple-500 rounded-lg" />
              <span className="font-bold text-xl text-white">Wish Directory</span>
            </div>
            <p className="text-sm mb-4">
              Your curated marketplace of dreams. Discover handpicked collections 
              to help you achieve your goals.
            </p>
            <div className="flex space-x-4">
              <a href="#" className="hover:text-white transition">
                <Twitter className="w-5 h-5" />
              </a>
              <a href="#" className="hover:text-white transition">
                <Github className="w-5 h-5" />
              </a>
              <a href="#" className="hover:text-white transition">
                <Linkedin className="w-5 h-5" />
              </a>
            </div>
          </div>

          {/* Links */}
          <div>
            <h3 className="font-semibold text-white mb-4">Product</h3>
            <ul className="space-y-2 text-sm">
              <li><Link href="/explore" className="hover:text-white transition">Explore</Link></li>
              <li><Link href="/categories" className="hover:text-white transition">Categories</Link></li>
              <li><Link href="/trending" className="hover:text-white transition">Trending</Link></li>
              <li><Link href="/create" className="hover:text-white transition">Create Wishboard</Link></li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h3 className="font-semibold text-white mb-4">Legal</h3>
            <ul className="space-y-2 text-sm">
              <li><Link href="/terms" className="hover:text-white transition">Terms of Service</Link></li>
              <li><Link href="/privacy" className="hover:text-white transition">Privacy Policy</Link></li>
              <li><Link href="/dmca" className="hover:text-white transition">DMCA</Link></li>
              <li><Link href="/contact" className="hover:text-white transition">Contact</Link></li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="mt-12 pt-8 border-t border-gray-800 text-sm text-center">
          <p>© 2024 Wish Directory. All rights reserved.</p>
          <p className="mt-2 text-xs">
            App information provided courtesy of iTunes. Affiliate links may earn commissions.
          </p>
        </div>
      </div>
    </footer>
  )
}