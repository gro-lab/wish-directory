// src/data/index.ts
import { Wishboard } from '@/lib/types';
import sampleDataJSON from './sample-wishboards.json';

// Type assertion for the imported JSON data
export const sampleData = sampleDataJSON as { wishboards: Wishboard[] };
export const sampleWishboards = sampleData.wishboards;

// Export individual getters if needed
export const getWishboardById = (id: string): Wishboard | undefined => {
  return sampleWishboards.find(wb => wb.id === id);
};

export const getWishboardsByCategory = (category: string): Wishboard[] => {
  return sampleWishboards.filter(wb => wb.category === category);
};

export const getWishboardsByAuthor = (authorName: string): Wishboard[] => {
  return sampleWishboards.filter(wb => wb.author.name === authorName);
};

// Export the raw data for API routes that need any types
export const sampleWishboardsRaw = sampleData.wishboards as any[];