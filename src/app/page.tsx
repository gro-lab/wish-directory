// src/app/page.tsx
import HeroSection from '@/components/home/HeroSection'
import WishboardCard from '@/components/wishboard/WishboardCard'
import sampleData from '@/data/sample-wishboards.json'

export default function Home() {
  return (
    <main className="min-h-screen">
      <HeroSection />
      
      {/* Featured Wishboards */}
      <section className="py-16 bg-gray-50">
        <div className="container mx-auto px-4">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900">Featured Wishboards</h2>
            <p className="mt-4 text-gray-600">
              Handpicked collections to inspire your next journey
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {sampleData.wishboards.map((wishboard) => (
              <WishboardCard key={wishboard.id} wishboard={wishboard} />
            ))}
          </div>
        </div>
      </section>
    </main>
  )
}