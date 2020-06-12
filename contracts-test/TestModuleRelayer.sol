// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.10;
import "../contracts/modules/common/BaseModule.sol";
import "../contracts/modules/common/RelayerModule.sol";

/**
 * @title TestModuleRelayer
 * @dev Basic test module subclassing RelayerModule
 * @author Olivier VDB - <olivier@argent.xyz>
 */
contract TestModuleRelayer is BaseModule, RelayerModule {

    bytes32 constant NAME = "TestModuleRelayer";

    bool boolVal;
    uint uintVal;

    constructor(IModuleRegistry _registry, bool _boolVal, uint _uintVal) BaseModule(_registry, IGuardianStorage(0), NAME) public {
        boolVal = _boolVal;
        uintVal = _uintVal;
    }

    function invalidOwnerChange(address _wallet) external {
        IWallet(_wallet).setOwner(address(0)); // this should fail
    }

    function setIntOwnerOnly(address _wallet, uint _val) external onlyWalletOwner(_wallet) {
        uintVal = _val;
    }
    function clearInt() external {
        uintVal = 0;
    }

    // used to simulate a bad module in MakerV2Loan tests
    function callContract(address _contract, uint256 _value, bytes calldata _data) external {
        // solium-disable-next-line security/no-call-value
        (bool success,) = _contract.call.value(_value)(_data);
        if (!success) {
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function init(address _wallet) public override onlyWallet(_wallet) {
        enableStaticCalls(_wallet, address(this));
    }

    function enableStaticCalls(address _wallet, address _module) public {
        IWallet(_wallet).enableStaticCall(_module, bytes4(keccak256("getBoolean()")));
        IWallet(_wallet).enableStaticCall(_module, bytes4(keccak256("getUint()")));
        IWallet(_wallet).enableStaticCall(_module, bytes4(keccak256("getAddress(address)")));
    }

    function getBoolean() public view returns (bool) {
        return boolVal;
    }

    function getUint() public view returns (uint) {
        return uintVal;
    }

    function getAddress(address _addr) public pure returns (address) {
        return _addr;
    }

    // *************** Implementation of RelayerModule methods ********************* //

    // Overrides to use the incremental nonce and save some gas
    function checkAndUpdateUniqueness(address _wallet, uint256 _nonce, bytes32 /* _signHash */) internal override returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function getRequiredSignatures(address /* _wallet */, bytes memory /*_data */) public view override returns (uint256, OwnerSignature) {
        return (1, OwnerSignature.Required);
    }
}