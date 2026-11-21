// Helpers for building safe queries from user input

// Escape a string so it matches literally inside a RegExp (search boxes)
const escapeRegex = (text) => String(text).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Case-insensitive "contains" regex for a search term
const containsRegex = (text) => ({ $regex: escapeRegex(String(text).slice(0, 100)), $options: 'i' });

// Parse ?page & ?limit with sane bounds
const pagination = (query, { defaultLimit = 20, maxLimit = 100 } = {}) => {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(maxLimit, Math.max(1, parseInt(query.limit, 10) || defaultLimit));
  return { page, limit, skip: (page - 1) * limit };
};

module.exports = { escapeRegex, containsRegex, pagination };
