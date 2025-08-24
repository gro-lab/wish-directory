// src/components/wishboard/WishboardCard.tsx
import Link from 'next/link'
import { Clock, Eye, Bookmark, Tag } from 'lucide-react'
import Image from 'next/image'
import { Wishboard } from '@/lib/types'

interface WishboardCardProps {
  wishboard: Wishboard
}

export default function WishboardCard({ wishboard }: WishboardCardProps) {
  return (
    <Link href={`/wishboard/${wishboard.id}`}>
      <article className="group bg-white rounded-xl overflow-hidden card-shadow hover:card-shadow-hover transition-all duration-300 hover:-translate-y-1">
        {/* Cover Image/Gradient */}
        <div className={`h-48 bg-gradient-to-br ${wishboard.coverGradient || 'from-indigo-400 to-purple-600'} relative`}>
          <div className="absolute top-4 left-4">
            <span className="px-3 py-1 bg-white/90 backdrop-blur text-sm font-medium rounded-full">
              {wishboard.category}
            </span>
          </div>
          <div className="absolute bottom-4 right-4 text-white">
            <span className="text-2xl font-bold">{wishboard.stats.items || wishboard.items?.length || 0}</span>
            <span className="text-sm ml-1">items</span>
          </div>
        </div>

        {/* Content */}
        <div className="p-6">
          <h3 className="text-xl font-semibold text-gray-900 group-hover:text-indigo-600 transition line-clamp-1">
            {wishboard.title}
          </h3>
          <p className="mt-2 text-gray-600 text-sm line-clamp-2">
            {wishboard.description}
          </p>

          {/* Author */}
          <div className="mt-4 flex items-center">
            <img
              src={wishboard.author.avatar}
              alt={wishboard.author.name}
              className="w-8 h-8 rounded-full"
            />
            <span className="ml-2 text-sm text-gray-700">{wishboard.author.name}</span>
          </div>

          {/* Stats */}
          <div className="mt-4 flex items-center justify-between text-sm text-gray-500">
            <div className="flex items-center space-x-4">
              <span className="flex items-center">
                <Eye className="w-4 h-4 mr-1" />
                {wishboard.stats.views.toLocaleString()}
              </span>
              <span className="flex items-center">
                <Bookmark className="w-4 h-4 mr-1" />
                {wishboard.stats.saves}
              </span>
            </div>
            <span className="flex items-center">
              <Clock className="w-4 h-4 mr-1" />
              {wishboard.estimatedTime}
            </span>
          </div>

          {/* Difficulty Badge */}
          <div className="mt-4">
            <span className={`inline-block px-2 py-1 text-xs font-medium rounded
              ${wishboard.difficulty === 'Beginner' ? 'bg-green-100 text-green-700' : ''}
              ${wishboard.difficulty === 'Intermediate' ? 'bg-yellow-100 text-yellow-700' : ''}
              ${wishboard.difficulty === 'Advanced' ? 'bg-red-100 text-red-700' : ''}
            `}>
              {wishboard.difficulty}
            </span>
          </div>
        </div>
      </article>
    </Link>
  )
}