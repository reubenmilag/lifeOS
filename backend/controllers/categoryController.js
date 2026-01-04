import Category from '../models/Category.js';

// Helper to seed hierarchical categories
const seedCategories = async () => {
  const categoryData = [
    // EXPENSE CATEGORIES
    {
      name: 'Food & Drink',
      icon: 'restaurant',
      color: '#FF5722',
      type: 'expense',
      children: [
        { name: 'General - Food & Drinks', icon: 'restaurant', color: '#FF5722' },
        { name: 'Bar', icon: 'local_bar', color: '#FF7043' },
        { name: 'Cafe', icon: 'local_cafe', color: '#FF8A65' },
        { name: 'Groceries', icon: 'shopping_cart', color: '#FF9E80' },
        { name: 'Restaurant', icon: 'restaurant_menu', color: '#FFAB91' },
        { name: 'Fast Food', icon: 'fastfood', color: '#FFCCBC' },
      ]
    },
    {
      name: 'Shopping',
      icon: 'shopping_bag',
      color: '#E91E63',
      type: 'expense',
      children: [
        { name: 'General - Shopping', icon: 'shopping_bag', color: '#E91E63' },
        { name: 'Clothes', icon: 'checkroom', color: '#EC407A' },
        { name: 'Shoes', icon: 'hiking', color: '#F06292' },
        { name: 'Chemist', icon: 'local_pharmacy', color: '#F48FB1' },
        { name: 'Electronics & Accessories', icon: 'devices', color: '#F8BBD9' },
        { name: 'Free Time', icon: 'sports_esports', color: '#FCE4EC' },
        { name: 'Gifts', icon: 'card_giftcard', color: '#AD1457' },
        { name: 'Joy', icon: 'celebration', color: '#C2185B' },
        { name: 'Health', icon: 'favorite', color: '#D81B60' },
        { name: 'Beauty', icon: 'spa', color: '#E91E63' },
        { name: 'Home', icon: 'home', color: '#F06292' },
        { name: 'Garden', icon: 'yard', color: '#F48FB1' },
        { name: 'Jewellery & Accessories', icon: 'diamond', color: '#880E4F' },
        { name: 'Kids', icon: 'child_care', color: '#C51162' },
        { name: 'Pets & Animals', icon: 'pets', color: '#FF4081' },
        { name: 'Stationery & Tools', icon: 'construction', color: '#FF80AB' },
      ]
    },
    {
      name: 'Housing',
      icon: 'home',
      color: '#795548',
      type: 'expense',
      children: [
        { name: 'General - Housing', icon: 'home', color: '#795548' },
        { name: 'Energy & Utilities', icon: 'bolt', color: '#8D6E63' },
        { name: 'Maintenance & Repairs', icon: 'build', color: '#A1887F' },
        { name: 'Mortgage', icon: 'account_balance', color: '#BCAAA4' },
        { name: 'Property Insurance', icon: 'security', color: '#D7CCC8' },
        { name: 'Rent', icon: 'key', color: '#5D4037' },
        { name: 'Services', icon: 'cleaning_services', color: '#4E342E' },
      ]
    },
    {
      name: 'Transportation',
      icon: 'directions_bus',
      color: '#2196F3',
      type: 'expense',
      children: [
        { name: 'General - Transportation', icon: 'directions_bus', color: '#2196F3' },
        { name: 'Business Trips', icon: 'business_center', color: '#42A5F5' },
        { name: 'Long Distance', icon: 'flight', color: '#64B5F6' },
        { name: 'Public Transport', icon: 'train', color: '#90CAF9' },
        { name: 'Taxi', icon: 'local_taxi', color: '#BBDEFB' },
      ]
    },
    {
      name: 'Vehicle',
      icon: 'directions_car',
      color: '#607D8B',
      type: 'expense',
      children: [
        { name: 'General - Vehicle', icon: 'directions_car', color: '#607D8B' },
        { name: 'Fuel', icon: 'local_gas_station', color: '#78909C' },
        { name: 'Leasing', icon: 'assignment', color: '#90A4AE' },
        { name: 'Parking', icon: 'local_parking', color: '#B0BEC5' },
        { name: 'Rentals', icon: 'car_rental', color: '#CFD8DC' },
        { name: 'Vehicle Insurance', icon: 'verified_user', color: '#546E7A' },
        { name: 'Vehicle Maintenance', icon: 'car_repair', color: '#455A64' },
      ]
    },
    {
      name: 'Life & Entertainment',
      icon: 'theater_comedy',
      color: '#9C27B0',
      type: 'expense',
      children: [
        { name: 'General - Life & Entertainment', icon: 'theater_comedy', color: '#9C27B0' },
        { name: 'Active Sport, Fitness', icon: 'fitness_center', color: '#AB47BC' },
        { name: 'Alcohol, Tobacco', icon: 'smoking_rooms', color: '#BA68C8' },
        { name: 'Books, Audio, Subscriptions', icon: 'library_books', color: '#CE93D8' },
        { name: 'Charity, Gifts', icon: 'volunteer_activism', color: '#E1BEE7' },
        { name: 'Culture, Sports Events', icon: 'stadium', color: '#8E24AA' },
        { name: 'Education', icon: 'school', color: '#7B1FA2' },
        { name: 'Development', icon: 'psychology', color: '#6A1B9A' },
        { name: 'Health Care, Doctor', icon: 'medical_services', color: '#4A148C' },
        { name: 'Hobbies', icon: 'brush', color: '#AA00FF' },
        { name: 'Holiday, Trips, Hotels', icon: 'luggage', color: '#D500F9' },
        { name: 'Life Events', icon: 'cake', color: '#E040FB' },
        { name: 'Lottery, Gambling', icon: 'casino', color: '#EA80FC' },
        { name: 'TV, Streaming', icon: 'live_tv', color: '#9C27B0' },
        { name: 'Wellness, Beauty', icon: 'self_improvement', color: '#AB47BC' },
      ]
    },
    {
      name: 'Communication, PC',
      icon: 'computer',
      color: '#00BCD4',
      type: 'expense',
      children: [
        { name: 'General - Communication, PC', icon: 'computer', color: '#00BCD4' },
        { name: 'Internet', icon: 'wifi', color: '#26C6DA' },
        { name: 'Phone, Cell Phone', icon: 'phone_android', color: '#4DD0E1' },
        { name: 'Postal Services', icon: 'mail', color: '#80DEEA' },
        { name: 'Software, Apps, Games', icon: 'apps', color: '#B2EBF2' },
      ]
    },
    {
      name: 'Financial Expenses',
      icon: 'account_balance',
      color: '#F44336',
      type: 'expense',
      children: [
        { name: 'General - Financial Expenses', icon: 'account_balance', color: '#F44336' },
        { name: 'Advisory', icon: 'support_agent', color: '#EF5350' },
        { name: 'Charges, Fees', icon: 'receipt_long', color: '#E57373' },
        { name: 'Child Support', icon: 'family_restroom', color: '#EF9A9A' },
        { name: 'Fines', icon: 'gavel', color: '#FFCDD2' },
        { name: 'Insurances', icon: 'health_and_safety', color: '#E53935' },
        { name: 'Loan, Interests', icon: 'money_off', color: '#D32F2F' },
        { name: 'Taxes', icon: 'receipt', color: '#C62828' },
      ]
    },
    {
      name: 'Investments',
      icon: 'trending_up',
      color: '#4CAF50',
      type: 'expense',
      children: [
        { name: 'General - Investments', icon: 'trending_up', color: '#4CAF50' },
        { name: 'Collections', icon: 'collections', color: '#66BB6A' },
        { name: 'Financial Investments', icon: 'insert_chart', color: '#81C784' },
        { name: 'Realty', icon: 'real_estate_agent', color: '#A5D6A7' },
        { name: 'Savings', icon: 'savings', color: '#C8E6C9' },
        { name: 'Vehicles, Chattels', icon: 'directions_car', color: '#43A047' },
        { name: 'Crypto', icon: 'currency_bitcoin', color: '#388E3C' },
        { name: 'Mutual Funds', icon: 'pie_chart', color: '#2E7D32' },
        { name: 'Equity', icon: 'show_chart', color: '#1B5E20' },
      ]
    },
    {
      name: 'Business / Work',
      icon: 'business',
      color: '#3F51B5',
      type: 'expense',
      children: [
        { name: 'General - Business', icon: 'business', color: '#3F51B5' },
        { name: 'Office Supplies', icon: 'inventory_2', color: '#5C6BC0' },
        { name: 'Client Entertainment', icon: 'groups', color: '#7986CB' },
        { name: 'Travel & Accommodation', icon: 'hotel', color: '#9FA8DA' },
        { name: 'Professional Services', icon: 'engineering', color: '#C5CAE9' },
        { name: 'Training & Certifications', icon: 'workspace_premium', color: '#303F9F' },
      ]
    },
    {
      name: 'Family & Personal',
      icon: 'family_restroom',
      color: '#009688',
      type: 'expense',
      children: [
        { name: 'General - Family', icon: 'family_restroom', color: '#009688' },
        { name: 'Childcare', icon: 'child_friendly', color: '#26A69A' },
        { name: 'School Fees', icon: 'school', color: '#4DB6AC' },
        { name: 'Allowances', icon: 'payments', color: '#80CBC4' },
        { name: 'Elder Care', icon: 'elderly', color: '#B2DFDB' },
      ]
    },
    {
      name: 'Subscriptions',
      icon: 'subscriptions',
      color: '#FF9800',
      type: 'expense',
      children: [
        { name: 'General - Subscriptions', icon: 'subscriptions', color: '#FF9800' },
        { name: 'Music', icon: 'music_note', color: '#FFA726' },
        { name: 'Video Streaming', icon: 'movie', color: '#FFB74D' },
        { name: 'Cloud Services', icon: 'cloud', color: '#FFCC80' },
        { name: 'Productivity Tools', icon: 'build_circle', color: '#FFE0B2' },
      ]
    },
    {
      name: 'Emergency & One-Off',
      icon: 'warning',
      color: '#FF5252',
      type: 'expense',
      children: [
        { name: 'Emergency', icon: 'emergency', color: '#FF5252' },
        { name: 'Medical Emergency', icon: 'local_hospital', color: '#FF8A80' },
        { name: 'Repairs (Unexpected)', icon: 'home_repair_service', color: '#FF1744' },
        { name: 'One-Time Purchases', icon: 'shopping_bag', color: '#D50000' },
      ]
    },
    {
      name: 'Others',
      icon: 'more_horiz',
      color: '#9E9E9E',
      type: 'expense',
      children: [
        { name: 'General - Others', icon: 'more_horiz', color: '#9E9E9E' },
        { name: 'Missing', icon: 'help_outline', color: '#BDBDBD' },
      ]
    },
    // INCOME CATEGORIES
    {
      name: 'Income',
      icon: 'attach_money',
      color: '#4CAF50',
      type: 'income',
      children: [
        { name: 'General - Income', icon: 'attach_money', color: '#4CAF50' },
        { name: 'Salary', icon: 'payments', color: '#66BB6A' },
        { name: 'Bonus', icon: 'card_giftcard', color: '#81C784' },
        { name: 'Freelance / Side Hustle', icon: 'work', color: '#A5D6A7' },
        { name: 'Interest Earned', icon: 'savings', color: '#C8E6C9' },
        { name: 'Dividends', icon: 'trending_up', color: '#43A047' },
        { name: 'Rental Income', icon: 'home', color: '#388E3C' },
      ]
    },
  ];

  const created = [];
  let order = 0;

  for (const parent of categoryData) {
    // Create parent category
    const parentDoc = await Category.create({
      name: parent.name,
      icon: parent.icon,
      color: parent.color,
      type: parent.type,
      parentId: null,
      order: order++
    });
    created.push(parentDoc);

    // Create children
    let childOrder = 0;
    for (const child of parent.children) {
      const childDoc = await Category.create({
        name: child.name,
        icon: child.icon,
        color: child.color,
        type: parent.type,
        parentId: parentDoc._id,
        order: childOrder++
      });
      created.push(childDoc);
    }
  }

  return created;
};

export const getCategories = async (request, reply) => {
  try {
    const categories = await Category.find().sort({ order: 1 });
    
    // Seed default categories if empty
    if (categories.length === 0) {
      const created = await seedCategories();
      
      // Build hierarchical structure
      const parentCategories = created.filter(c => !c.parentId);
      const result = parentCategories.map(parent => ({
        ...parent.toJSON(),
        children: created.filter(c => c.parentId?.toString() === parent._id.toString())
      }));
      
      return result;
    }
    
    // Build hierarchical structure
    const parentCategories = categories.filter(c => !c.parentId);
    const result = parentCategories.map(parent => ({
      ...parent.toJSON(),
      children: categories.filter(c => c.parentId?.toString() === parent._id.toString())
    }));
    
    return result;
  } catch (error) {
    console.error('Error fetching categories:', error);
    reply.code(500).send({ error: 'Failed to fetch categories' });
  }
};

// Get flat list of all categories (for backwards compatibility)
export const getFlatCategories = async (request, reply) => {
  try {
    const categories = await Category.find().sort({ order: 1 });
    
    if (categories.length === 0) {
      return await seedCategories();
    }
    
    return categories;
  } catch (error) {
    console.error('Error fetching flat categories:', error);
    reply.code(500).send({ error: 'Failed to fetch categories' });
  }
};

// Reset and reseed categories
export const resetCategories = async (request, reply) => {
  try {
    await Category.deleteMany({});
    const created = await seedCategories();
    
    const parentCategories = created.filter(c => !c.parentId);
    const result = parentCategories.map(parent => ({
      ...parent.toJSON(),
      children: created.filter(c => c.parentId?.toString() === parent._id.toString())
    }));
    
    return result;
  } catch (error) {
    console.error('Error resetting categories:', error);
    reply.code(500).send({ error: 'Failed to reset categories' });
  }
};
