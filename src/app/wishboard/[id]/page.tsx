// src/app/wishboard/[id]/page.tsx
import { notFound } from 'next/navigation'
import { ArrowLeft, Share2, Bookmark, Clock, User, Tag } from 'lucide-react'
import Link from 'next/link'
import sampleData from '@/data/sample-wishboards.json'

export default function WishboardDetailPage({ 
  params 
}: { 
  params: { id: string } 
}) {
  const wishboard = sampleData.wishboards.find(wb => wb.id === params.id)
  
  if (!wishboard) {
    notFound()
  }

  return (
    <main className="min-h-screen bg-gray-50">
      {/* Hero Section */}
      <div className={`h-64 bg-gradient-to-br ${wishboard.coverGradient} relative`}>
        <div className="absolute inset-0 bg-black/20" />
        <div className="relative container mx-auto px-4 h-full flex items-center">
          <Link 
            href="/" 
            className="absolute top-8 left-4 text-white hover:text-gray-200 transition"
          >
            <ArrowLeft className="w-6 h-6" />
          </Link>
        </div>
      </div>

      {/* Content */}
      <div className="container mx-auto px-4 -mt-20 relative z-10">
        <div className="bg-white rounded-xl shadow-xl p-8">
          {/* Header */}
          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-6">
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-4">
                <span className="px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm font-medium">
                  {wishboard.category}
                </span>
                <span className={`px-3 py-1 rounded-full text-sm font-medium
                  ${wishboard.difficulty === 'beginner' ? 'bg-green-100 text-green-700' : ''}
                  ${wishboard.difficulty === 'intermediate' ? 'bg-yellow-100 text-yellow-700' : ''}
                  ${wishboard.difficulty === 'advanced' ? 'bg-red-100 text-red-700' : ''}
                `}>
                  {wishboard.difficulty}
                </span>
              </div>
              
              <h1 className="text-4xl font-bold text-gray-900 mb-4">
                {wishboard.title}
              </h1>
              
              <p className="text-lg text-gray-600 mb-6">
                {wishboard.description}
              </p>

              {/* Author */}
              <div className="flex items-center gap-4 mb-6">
                <img
                  src={wishboard.author.avatar}
                  alt={wishboard.author.name}
                  className="w-12 h-12 rounded-full"
                />
                <div>
                  <p className="font-medium text-gray-900">{wishboard.author.name}</p>
                  <p className="text-sm text-gray-500">Curator</p>
                </div>
              </div>

              {/* Tags */}
              <div className="flex flex-wrap gap-2 mb-6">
                {wishboard.tags.map((tag) => (
                  <span 
                    key={tag}
                    className="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm"
                  >
                    #{tag}
                  </span>
                ))}
              </div>
            </div>

            {/* Sidebar */}
            <div className="lg:w-80">
              <div className="bg-gray-50 rounded-lg p-6">
                <div className="flex items-center justify-between mb-4">
                  <span className="flex items-center text-gray-600">
                    <Clock className="w-5 h-5 mr-2" />
                    {wishboard.estimatedTime}
                  </span>
                  <span className="text-2xl font-bold text-gray-900">
                    {wishboard.stats.items} items
                  </span>
                </div>
                
                <div className="space-y-3">
                  <button className="w-full py-3 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition flex items-center justify-center">
                    <Bookmark className="w-5 h-5 mr-2" />
                    Save Wishboard
                  </button>
                  <button className="w-full py-3 bg-white text-gray-700 font-medium rounded-lg border border-gray-300 hover:border-gray-400 transition flex items-center justify-center">
                    <Share2 className="w-5 h-5 mr-2" />
                    Share
                  </button>
                </div>

                <div className="mt-6 pt-6 border-t border-gray-200">
                  <div className="flex justify-between text-sm text-gray-600">
                    <span>{wishboard.stats.views.toLocaleString()} views</span>
                    <span>{wishboard.stats.saves} saves</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Items Preview */}
          <div className="mt-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Items in this Wishboard</h2>
            <div className="bg-gray-100 rounded-lg p-8 text-center">
              <p className="text-gray-600">
                Items will be displayed here in the next sprint
              </p>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}