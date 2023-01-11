#!/bin/bash

set -v
# This is a script to demonstrate the capabilities of this DApp

REGISTRY="0x5FbDB2315678afecb367f032d93F642f64180aa3"

# 1) This command deploys the contract on the local network:
npx hardhat run scripts/deploy.js --network localhost

# 2) This allows you to determine the number of verifiers:
npx hardhat getVerifierCount --registry $REGISTRY --network localhost

# 3) This allows you to check whether the address is a trusted verifier
npx hardhat isVerifier --registry $REGISTRY --address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --network localhost

npx hardhat isVerifier --registry $REGISTRY --address 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc --network localhost

# 4) Similarly, you can work with verifiable credentials
npx hardhat getVerificationCount --registry $REGISTRY --network localhost

npx hardhat isVerified --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost

npx hardhat isVerified --registry $REGISTRY --address 0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc --network localhost

# 5) Other credentials can be verified:
npx hardhat registerVerification --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost

npx hardhat isVerified --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost

# 6) You can also get a list of all verified credentials at
# the verifier address using the following command:
npx hardhat getVerificationsForVerifier --registry $REGISTRY --verifier 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --network localhost

UUID=$(npx hardhat getVerificationsForVerifier --registry $REGISTRY --verifier 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --network localhost | grep 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 | awk -F ',' '{print $1}')
echo ${UUID} # Verifiable credentials has UUID (assined in smart-contract)

# 7) If you have a UUID, you can cancel the confirmation:
npx hardhat revokeVerification --registry $REGISTRY --uuid ${UUID} --network localhost

npx hardhat isVerified --registry $REGISTRY --address 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199 --network localhost
