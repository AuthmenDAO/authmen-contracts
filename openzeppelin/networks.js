const { alchemyApiKey, mnemonic } = require('./secrets.json');
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
	kovan: {
		provider: () => new HDWalletProvider(
       		mnemonic, `https://eth-kovan.alchemyapi.io/v2/G2Ox7P8GUiKvwsA886eCR-jSR7NWq9ob`
    	),
		network_id: 42,
    	gasPrice: 10e9,
    	skipDryRun: true,
    	networkCheckTimeout: 1000000
  },
}
};
