// src/components/home/HeroSection.tsx
import { ArrowRight, Sparkles } from 'lucide-react'

export default function HeroSection() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-indigo-50 via-white to-purple-50">
      {/* Background decoration */}
      <div className="absolute inset-0 bg-grid-pattern opacity-5" />
      <div className="absolute -top-40 -right-40 w-80 h-80 bg-purple-300 rounded-full blur-3xl opacity-20" />
      <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-indigo-300 rounded-full blur-3xl opacity-20" />
      
      <div className="relative container mx-auto px-4 py-24">
        <div className="max-w-4xl mx-auto text-center">
          {/* Badge */}
          <div className="inline-flex items-center space-x-2 px-4 py-2 bg-indigo-100 rounded-full mb-6">
            <Sparkles className="w-4 h-4 text-indigo-600" />
            <span className="text-sm font-medium text-indigo-700">
              Discover your next journey
            </span>
          </div>

          {/* Heading */}
          <h1 className="text-5xl md:text-6xl font-bold text-gray-900 leading-tight">
            Your Curated
            <span className="gradient-text"> Marketplace </span>
            of Dreams
          </h1>

          {/* Description */}
          <p className="mt-6 text-xl text-gray-600 max-w-2xl mx-auto">
            Discover handpicked collections of apps, tools, and resources to help you 
            achieve your goals, master new skills, and explore your interests.
          </p>

          {/* CTA Buttons */}
          <div className="mt-10 flex flex-col sm:flex-row gap-4 justify-center">
            <button className="px-8 py-4 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 transition flex items-center justify-center group">
              Explore Wishboards
              <ArrowRight className="ml-2 w-4 h-4 group-hover:translate-x-1 transition" />
            </button>
            <button className="px-8 py-4 bg-white text-gray-700 font-medium rounded-lg border border-gray-300 hover:border-gray-400 transition">
              Create Your Own
            </button>
          </div>

          {/* Stats */}
          <div className="mt-16 grid grid-cols-3 gap-8 max-w-lg mx-auto">
            <div>
              <div className="text-3xl font-bold text-gray-900">500+</div>
              <div className="text-sm text-gray-600">Wishboards</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-gray-900">10k+</div>
              <div className="text-sm text-gray-600">Users</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-gray-900">50k+</div>
              <div className="text-sm text-gray-600">Items Curated</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}