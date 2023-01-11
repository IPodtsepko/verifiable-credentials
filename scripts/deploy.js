const runtime = require('hardhat')
const { Contract, ContractFactory } = require('ethers')

async function main() {
    if (runtime.network.name === 'hardhat') {
        console.warn(
            'Perhaps the option was forgotten \'--network localhost\''
        )
    }

    const [deployer] = await runtime.ethers.getSigners()
    console.log(
        'Deploying the contracts with the account:',
        await deployer.getAddress()
    )

    console.log('Account balance:', (await deployer.getBalance()).toString())

    const VerifiableDataRegistry = await runtime.ethers.getContractFactory('VerifiableDataRegistry')
    const registry = await VerifiableDataRegistry.deploy()
    await registry.deployed()
    console.log('Registry address:', registry.address)

    const verifiers = [
        await deployer.getAddress(),
        '0x71CB05EE1b1F506fF321Da3dac38f25c0c9ce6E1'
    ]
    await createTrustedVerifier(verifiers, registry)

    const addresses = [
        '0x695f7BC02730E0702bf9c8C102C254F595B24161',
        '0x71CB05EE1b1F506fF321Da3dac38f25c0c9ce6E1',
        '0x70997970c51812dc3a010c7d01b50e0d17dc79c8',
        '0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc',
        '0x90f79bf6eb2c4f870365e785982e1f101e93b906'
    ]
    await registerVerifications(registry, addresses)
}

async function createTrustedVerifier(verifiers, registry) {
    for (const address of verifiers) {
        const itmo = {
            name: runtime.ethers.utils.formatBytes32String('ITMO University'),
            signer: address
        }

        const addVerifierTx = await registry.addVerifier(address, itmo)
        await addVerifierTx.wait()

        console.log('Added trusted verifier:', address)
    }
}

async function registerVerifications(registry, addresses) {
    const domain = {
        name: 'VerifiableDataRegistry',
        version: '1.0',
        chainId: runtime.network.config.chainId ?? 1337,
        verifyingContract: registry.address
    }

    const types = {
        VerifiedCredentials: [
            { name: 'subject', type: 'address' },
            { name: 'expirationTime', type: 'uint256' }
        ]
    }

    const expirationTime = Math.floor(Date.now() / 1000) + 31_536_000 * 10

    for (const address of addresses) {
        const verificationResult = {
            subject: address,
            expirationTime: expirationTime
        }

        const [deployer] = await runtime.ethers.getSigners()

        const signature = await deployer._signTypedData(domain, types, verificationResult)

        const tx = await registry.registerVerification(verificationResult, signature)
        await tx.wait()

        console.log(
            `Registered Verification for address: ${address}, by verifier: ${await deployer.getAddress()}`
        )
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
