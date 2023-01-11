// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/**
 * @dev A structure that combines the necessary information about verifiers.
 */
struct Verifier {
    // The name of the organization or the name of an individual.
    bytes32 name;
    // Address of verifier.
    address signer;
}

/**
 * @dev A structure that combines information about verifiable credentials that the verifier must provide.
 */
struct VerifiedCredentials {
    // Address of subject.
    address subject;
    // The time after which the credentials are considered expired.
    uint256 expirationTime;
}

/**
 * @dev A structure that combines all the necessary information about verifiable credentials.
 */
struct VerifiedCredentialsData {
    // Credentials UUID.
    bytes32 uuid;
    // An address of the verifier that confirmed the credentials.
    address verifier;
    // Address of subject.
    address subject;
    // Date the credentials were issued.
    uint256 issueTime;
    // The time after which the credentials are considered expired.
    uint256 expirationTime;
    // Flag indicating whether the data has been revoked.
    bool revoked;
}

/**
 * @title Verifiable Data Registry
 *
 * @dev Provides a CRUD facade for working with verifiers and verifiable credentials.
 */
contract VerifiableDataRegistry is
    Ownable,
    EIP712("VerifiableDataRegistry", "1.0")
{
    /**
     * @dev An event that informs that a trusted verifier has been added.
     * @param account Verifier address.
     * @param verifier Data of the added verifier.
     */
    event VerifierAdded(address account, Verifier verifier);
    /**
     * @dev Event that informs that the verifier data has been updated.
     * @param account Verifier address.
     * @param verifier Updated verifier data.
     */
    event VerifierUpdated(address account, Verifier verifier);
    /**
     * @dev An event that informs that a verifier has been removed.
     * @param account Verifier address.
     */
    event VerifierRemoved(address account);

    /**
     * @dev Event that informs that verifiable credentials have been confirmed by the verifier.
     * @param data Data of the confirmed credentials.
     */
    event CredentialsVerified(VerifiedCredentialsData data);
    /**
     * @dev Event that informs that verifiable credentials have been revoked by the verifier.
     * @param uuid Identifier of the confirmed credentials.
     */
    event VerificationRevoked(bytes32 uuid);
    /**
     * @dev Event that informs that verifiable credentials have been removed by the verifier.
     * @param uuid Identifier of the confirmed credentials.
     */
    event VerificationRemoved(bytes32 uuid);

    // A mapping containing information about verifiers available at their addresses.
    mapping(address => Verifier) private mVerifiers;

    // Verifier signing keys mapped to their addresses.
    mapping(address => address) private mSigners;

    // Count of trusted verifiers.
    uint256 mCountOfVerifiers;

    // A mapping containing information about verifible credentials available at their UUIDs.
    mapping(bytes32 => VerifiedCredentialsData) private mVerifiedCredentials;

    // A mapping comtaining information about verifiable credentials UUIDs by subjects.
    mapping(address => bytes32[]) private mVerifiedCredentialsUuids;

    // A mapping that contains information about which verifiable credentials have been
    // confirmed at the verifier's address.
    mapping(address => bytes32[]) private mCredentialsVerifiedByVerifier;

    // Total number of verifiable credentials.
    uint256 private mVerifiedCredentialsCount;

    /**
     * @dev A method that allows you to add a verifier.
     * @param account An address of the verifier.
     * @param verifier Information about the verifier being added.
     */
    function addVerifier(
        address account,
        Verifier memory verifier
    ) external onlyOwner {
        require(mVerifiers[account].name == 0, "Attempt to re-add an account");
        mVerifiers[account] = verifier;
        mSigners[verifier.signer] = account;
        mCountOfVerifiers++;
        emit VerifierAdded(account, verifier);
    }

    /**
     * @dev The method of checking whether the account is a verifier.
     * @param account Address of the account to check.
     */
    function isVerifier(address account) external view returns (bool) {
        return mVerifiers[account].name != 0;
    }

    /**
     * @dev Method that returns the total number of verifiers.
     */
    function getVerifierCount() external view returns (uint) {
        return mCountOfVerifiers;
    }

    /**
     * @dev A method that returns information to the verifier at its address.
     * @param account An address of the verifier.
     */
    function getVerifier(
        address account
    ) external view returns (Verifier memory) {
        Verifier memory verifier = mVerifiers[account];
        require(verifier.name != 0, "Unknown verifier");
        return verifier;
    }

    /**
     * @dev A method that allows to update information about verifier.
     * @param account An address of the verifier.
     * @param verifier Updated information about the verifier.
     */
    function updateVerifier(
        address account,
        Verifier memory verifier
    ) external onlyOwner {
        require(mVerifiers[account].name != 0, "Unknown verifier");
        mVerifiers[account] = verifier;
        mSigners[verifier.signer] = account;
        emit VerifierUpdated(account, verifier);
    }

    /**
     * @dev A method that allows to remove verifier from list of trusted.
     * @param account An address of the verifier.
     */
    function removeVerifier(address account) external onlyOwner {
        require(mVerifiers[account].name != 0, "Unknown verifier");
        delete mSigners[mVerifiers[account].signer];
        delete mVerifiers[account];
        mCountOfVerifiers--;
        emit VerifierRemoved(account);
    }

    /**
     * @dev Method that returns the total number of verifiable credentials.
     */
    function getVerificationCount() external view returns (uint256) {
        return mVerifiedCredentialsCount;
    }

    /**
     * @dev A method that checks if there is a confirmation for credentials.
     * @param subject An address of the subject.
     */
    function isVerified(address subject) external view returns (bool) {
        require(subject != address(0), "Invalid address (zero)");
        bytes32[] memory uuids = mVerifiedCredentialsUuids[subject];
        for (uint i = 0; i < uuids.length; i++) {
            VerifiedCredentialsData memory data = mVerifiedCredentials[
                uuids[i]
            ];
            if (!data.revoked && data.expirationTime > block.timestamp) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev A method that returns all information about credentials by their UUID.
     * @param uuid UUID of requested credentials.
     */
    function getVerification(
        bytes32 uuid
    ) external view returns (VerifiedCredentialsData memory) {
        return mVerifiedCredentials[uuid];
    }

    /**
     * @dev A method that returns all information about all credentials for subject.
     * @param subject An address of the subject.
     */
    function getVerificationsForSubject(
        address subject
    ) external view returns (VerifiedCredentialsData[] memory) {
        require(subject != address(0), "Invalid address");
        bytes32[] memory subjectRecords = mVerifiedCredentialsUuids[subject];
        VerifiedCredentialsData[]
            memory records = new VerifiedCredentialsData[](
                subjectRecords.length
            );
        for (uint i = 0; i < subjectRecords.length; i++) {
            VerifiedCredentialsData memory record = mVerifiedCredentials[
                subjectRecords[i]
            ];
            records[i] = record;
        }
        return records;
    }

    /**
     * @dev A method that returns all information about all credentials confirmed by verifier.
     * @param verifier An address of the verifier.
     */
    function getVerificationsForVerifier(
        address verifier
    ) external view returns (VerifiedCredentialsData[] memory) {
        require(verifier != address(0), "Invalid address");
        bytes32[] memory verifierRecords = mCredentialsVerifiedByVerifier[
            verifier
        ];
        VerifiedCredentialsData[]
            memory records = new VerifiedCredentialsData[](
                verifierRecords.length
            );
        for (uint i = 0; i < verifierRecords.length; i++) {
            VerifiedCredentialsData memory record = mVerifiedCredentials[
                verifierRecords[i]
            ];
            records[i] = record;
        }
        return records;
    }

    /**
     * @dev A method that allows you to revoke the confirmation of credentials.
     * @param uuid UUID of the credentials to be revoked.
     */
    function revokeVerification(bytes32 uuid) external onlyByVerifier {
        require(
            mVerifiedCredentials[uuid].verifier == msg.sender,
            "Caller is not the original verifier"
        );
        mVerifiedCredentials[uuid].revoked = true;
        emit VerificationRevoked(uuid);
    }

    /**
     * @dev A method that allows you to permanently delete the confirmation of credentials.
     * @param uuid UUID of the credentials to be removed.
     */
    function removeVerification(bytes32 uuid) external onlyByVerifier {
        require(
            mVerifiedCredentials[uuid].verifier == msg.sender,
            "Caller is not the verifier of the referenced record"
        );
        delete mVerifiedCredentials[uuid];
        emit VerificationRemoved(uuid);
    }

    /**
     * @dev Method that allows to add new verifiable credentials.
     * @param verifiedCredentials Verifiable credentials data.
     * @param signature Signature of the verifier.
     */
    function registerVerification(
        VerifiedCredentials memory verifiedCredentials,
        bytes memory signature
    ) external onlyByVerifier returns (VerifiedCredentialsData memory) {
        VerifiedCredentialsData memory data = validate(
            verifiedCredentials,
            signature
        );
        require(
            data.verifier == msg.sender,
            "Caller is not the verifier of the verification"
        );
        saveToStorage(data);
        emit CredentialsVerified(data);
        return data;
    }

    /**
     * @dev An auxiliary method that implements signature verification on
     * verifiable credentials and returns detailed data.
     * @param verifiedCredentials Minimum verifiable credentials data received from the verifier.
     * @param signature Signature of the verifier.
     */
    function validate(
        VerifiedCredentials memory verifiedCredentials,
        bytes memory signature
    ) internal view returns (VerifiedCredentialsData memory) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "VerifiedCredentials(address subject,uint256 expirationTime)"
                    ),
                    verifiedCredentials.subject,
                    verifiedCredentials.expirationTime
                )
            )
        );

        address signer = ECDSA.recover(digest, signature);
        address verifier = mSigners[signer];

        require(mVerifiers[verifier].signer == signer, "Invalid signature");
        require(
            verifiedCredentials.expirationTime > block.timestamp,
            "Verification expired"
        );

        VerifiedCredentialsData memory data = VerifiedCredentialsData({
            uuid: 0,
            verifier: verifier,
            subject: verifiedCredentials.subject,
            issueTime: block.timestamp,
            expirationTime: verifiedCredentials.expirationTime,
            revoked: false
        });

        data.uuid = getIdentifier(data);

        return data;
    }

    /**
     * @dev An auxiliary method that implements storing data about
     * verifiable credentials in storage.
     * @param data Data to saving.
     */
    function saveToStorage(VerifiedCredentialsData memory data) internal {
        mVerifiedCredentialsCount++;
        mVerifiedCredentials[data.uuid] = data;
        mVerifiedCredentialsUuids[data.subject].push(data.uuid);
        mCredentialsVerifiedByVerifier[data.verifier].push(data.uuid);
    }

    /**
     * @dev An auxiliary method that calculates a universal unique identifier (UUID)
     * for verifiable credentials data.
     * @param data Data to generate an UUID for.
     * @return Generated UUID.
     */
    function getIdentifier(
        VerifiedCredentialsData memory data
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    data.verifier,
                    data.subject,
                    data.issueTime,
                    data.expirationTime,
                    mVerifiedCredentialsCount
                )
            );
    }

    /**
     * @dev Allows to limit the number of users who can call the method to verifiers.
     */
    modifier onlyByVerifier() {
        require(
            mVerifiers[msg.sender].name != 0,
            "Permission denied (the call is allowed only by the verifier)"
        );
        _;
    }
}
