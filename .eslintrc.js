module.exports = {
  extends: 'airbnb-base',
  rules: {
    'import/no-unresolved': ['error', { ignore: ['atom'] }],
  },
  globals: {
    atom: true,
  },
};
