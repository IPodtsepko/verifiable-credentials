const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('VerifiableDataRegistry', function () {
  const mnemonic = 'test test test test test test test test test test test junk' // default hardhat mnemonic
  const wallet = ethers.Wallet.fromMnemonic(mnemonic)

  let subjectAddress
  it('Searches for a random address to be used as a verification object', async function () {
    const signers = await ethers.getSigners()
    const randomIndex = Math.floor(Math.random() * signers.length)
    subjectAddress = await signers[randomIndex].getAddress()
  })

  let registry, owner
  it('The registry must be successfully deployed', async function () {
    const VerifiableDataRegistry = await ethers.getContractFactory('VerifiableDataRegistry')
    registry = await VerifiableDataRegistry.deploy()
    await registry.deployed()
    owner = registry.deployTransaction.from
  })

  it('A verifier for an untrusted address should not be found', async function () {
    await expect(registry.getVerifier(owner)).to.be.reverted
  })

  // The university can verify students' diplomas.
  const itmo = {
    name: ethers.utils.formatBytes32String('ITMO University'),
    signer: wallet.address
  }

  it('The owner must be successfully registered as a verifier', async function () {
    const addVerifierTx = await registry.addVerifier(owner, itmo)
    await addVerifierTx.wait()
  })

  it('Cheks that the owner\'s address is now the address of the verifier', async function () {
    expect(await registry.isVerifier(owner)).to.be.true
  })

  it('Now there should be only one verifier', async function () {
    expect(await registry.getVerifierCount()).to.be.equal(1)
  })

  it('Data about a verifier should be available', async function () {
    const verifier = await registry.getVerifier(owner)
    expect(verifier.name).to.equal(itmo.name)
  })

  it('Verifier data must be updated successfully', async function () {
    itmo.name = ethers.utils.formatBytes32String('VITMO')
    const updateVerifierTx = await registry.updateVerifier(
      owner,
      itmo
    )
    await updateVerifierTx.wait()
    const retrievedVerifier = await registry.getVerifier(
      owner
    )
    expect(retrievedVerifier.url).to.equal(itmo.url)
  })

  it('The verifier must be successfully removed', async function () {
    const removeVerifierTx = await registry.removeVerifier(
      owner
    )
    await removeVerifierTx.wait()
    const verifierCount = await registry.getVerifierCount()
    expect(verifierCount).to.be.equal(0)
  })

  it('The owner must successfully recreate himself as a verifier', async function () {
    const addVerifierTx = await registry.addVerifier(owner, itmo)
    await addVerifierTx.wait()

    expect(await registry.getVerifierCount()).to.be.equal(1)
  })

  let expirationTime
  const lifetime = 300
  it(' Based on the time stamp on the last block, the confirmation \
expiration time should be determined', async function () {
    const provider = ethers.getDefaultProvider()
    const lastBlockNumber = await provider.getBlockNumber()
    const lastBlock = await provider.getBlock(lastBlockNumber)
    expirationTime = lastBlock.timestamp + lifetime
  })

  let domain, types, value
  it('Should format a structured verification result', async function () {
    domain = {
      name: 'VerifiableDataRegistry',
      version: '1.0',
      chainId: 1337, // Configured in hardhat.config.js
      verifyingContract: await registry.resolvedAddress
    }
    types = {
      VerifiedCredentials: [
        { name: 'subject', type: 'address' },
        { name: 'expirationTime', type: 'uint256' }
      ]
    }
    value = {
      subject: subjectAddress,
      expirationTime: expirationTime
    }
  })

  let signature
  it('The correct signature must be generated to verify the credentials', async function () {
    signature = await wallet._signTypedData(domain, types, value)
    const recoveredAddress = ethers.utils.verifyTypedData(domain, types, value, signature)
    expect(recoveredAddress).to.equal(itmo.signer)
  })

  it('The subject must not have a registered valid confirmation', async function () {
    expect(await registry.isVerified(owner)).to.be.false
  })

  it('The subject must be successfully registered as verified', async function () {
    const registerVerificationTx = await registry.registerVerification(value, signature)
    await registerVerificationTx.wait()

    expect(await registry.getVerificationCount()).to.be.equal(1)
  })

  it('Information about the confirmation of the subject must be available.', async function () {
    expect(await registry.isVerified(subjectAddress)).to.be.true
  })

  let verification
  it('Information about all verifications for a subject address must be available', async function () {
    const verifications = await registry.getVerificationsForSubject(subjectAddress)
    verification = verifications[0]
    expect(verifications.length).to.equal(1)
  })

  it('Information about all verifications for a verifier address must be available', async function () {
    const verifications = await registry.getVerificationsForVerifier(owner)
    expect(verifications[0].uuid).to.equal(verification.uuid)
    expect(verifications.length).to.equal(1)
  })

  it('Information about confirmation should be available by its UUID', async function () {
    const verificatonForUuid = await registry.getVerification(verification.uuid)
    expect(ethers.utils.getAddress(verificatonForUuid.subject)).not.to.throw
  })
})
