require('@nomiclabs/hardhat-waffle')

task('accounts', 'Prints the list of accounts', async function (arguments, runtime) {
  const signers = await runtime.ethers.getSigners()
  for (const signer of signers) {
    console.log(signer.address);
  }
})

task('isVerifier', 'Shows whether the address is a verifier')
  .addParam('registry', 'Address of the registry')
  .addParam('address', 'Address of the verifier')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)
    const isVerifier = await registry.isVerifier(arguments.address)
    console.log(`Is ${arguments.address} a verifier? ${isVerifier}`)
  })

task('getVerifierCount', 'Prints the number of verifiers')
  .addParam('registry', 'Address of the registry')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)
    const verifierCount = await registry.getVerifierCount()
    console.log(`Number of verifiers: ${verifierCount}`)
  })

task('getVerificationCount', 'Prints the total number of registered Verification Records')
  .addParam('registry', 'Address of the registry')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)
    const verificationCount = await registry.getVerificationCount()
    console.log(`Verification Count: ${verificationCount}`)
  })

task('isVerified', 'Shows whether the address is verified')
  .addParam('registry', 'Address of the registry')
  .addParam('address', 'Subject address')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)
    const isVerified = await registry.isVerified(arguments.address)
    console.log(`Is ${arguments.address} verified? ${isVerified}`)
  })

task('getVerificationsForVerifier', 'Retrieve all of the verification records associated with the verifier')
  .addParam('registry', 'Address of the registry')
  .addParam('verifier', 'Address of the verifier')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)
    const verificationsForVerifier = await registry.getVerificationsForVerifier(arguments.verifier)
    console.log(`Verifications from ${arguments.verifier}:\n${verificationsForVerifier.join('\n')}`)
  })

task('registerVerification', 'Register a Verification Record for the given address')
  .addParam('registry', 'Address of the registry')
  .addParam('address', 'Subject address to be verified')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)

    const domain = {
      name: 'VerifiableDataRegistry',
      version: '1.0',
      chainId: hre.network.config.chainId ?? 1337,
      verifyingContract: registry.address
    }

    const types = {
      VerifiedCredentials: [
        { name: 'subject', type: 'address' },
        { name: 'expirationTime', type: 'uint256' }
      ]
    }

    const verifiedCredentials = {
      subject: arguments.address,
      expirationTime: Math.floor(Date.now() / 1000) + 60 // 1 minute
    }

    const [deployer] = await hre.ethers.getSigners()

    const signature = await deployer._signTypedData(domain, types, verifiedCredentials)

    const tx = await registry.registerVerification(verifiedCredentials, signature)
    await tx.wait()

    console.log(
      `Registered Verification for address: ${arguments.address}, by verifier ${await deployer.getAddress()}`
    )
  })

task('revokeVerification', 'Revoke a Verification Record that was previously created')
  .addParam('registry', 'Address of the registry')
  .addParam('uuid', 'UUID of the verification record')
  .setAction(async function (arguments, runtime) {
    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = VerifiableDataRegistry.attach(arguments.registry)

    const tx = await registry.revokeVerification(arguments.uuid)
    await tx.wait()

    console.log(`Revoked verification with UUID: ${arguments.uuid}`)
  })

module.exports = {
  solidity: '0.8.4',
  networks: {
    hardhat: {
      chainId: 1337
    }
  }
}
