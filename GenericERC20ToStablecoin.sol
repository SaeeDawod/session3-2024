// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A generic ERC20 Token
/// @dev Extends ERC20 with burnable, pausable, and permit functionalities.
/// @custom:security-contact support@settlemint.com
contract GenericERC20 is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit, AccessControl {
    uint256 public collateralSupply;
    mapping(address => bool) public blocklisted;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev Initializes the contract by setting a `name` and a `symbol` to the token and mints initial tokens to the
    /// deploying address.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.

    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) ERC20Permit(name) {
        // _mint(msg.sender, 100_000 * 10 ** decimals());
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
    }

    //BlockList management functions

    function isBlocklisted(address account) public view returns (bool) {
        return blocklisted[account];
    }

    function addBlocklist(address account) public onlyOwner {
        blocklisted[account] = true;
    }

    function removeBlocklist(address account) public onlyOwner {
        blocklisted[account] = false;
    }

    //Collateral management functions;

    // Mint tokens in response to collateral deposit
    function depositCollateral(uint256 amount, address mintTo) external onlyRole(MINTER_ROLE) {
        collateralSupply += amount;
        _mint(mintTo, amount);
    }

    // Burn tokens in response to collateral withdrawal
    function withdrawCollateral(uint256 amount, address burnFrom) external onlyRole(BURNER_ROLE) {
        require(collateralSupply >= amount, "Insufficient collateral");
        collateralSupply -= amount;
        _burn(burnFrom, amount);
    }

    /// @dev Pauses all token transfers.
    /// @notice This function can only be called by the contract owner.

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev Unpauses all token transfers.
    /// @notice This function can only be called by the contract owner.
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Mints `amount` tokens and assigns them to `to`, increasing the total supply.
    /// @param to The address to mint tokens to.
    /// @param amount The number of tokens to be minted.
    /// @notice This function can only be called by the contract owner.
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= collateralSupply, "Insufficient collateral");
        require(!isBlocklisted(to), "GenericERC20: Recipient address is blocklisted");
        _mint(to, amount);
    }

    /// @dev Overrides the `_update` function of ERC20 and ERC20Pausable to ensure compatibility.
    /// @param from The address from which tokens are transferred.
    /// @param to The address to which tokens are transferred.
    /// @param value The amount of tokens to be transferred.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(!isBlocklisted(msg.sender), "GenericERC20: Sender address is blocklisted");
        require(!isBlocklisted(to), "GenericERC20: Recipient address is blocklisted");
        require(!paused(), "GenericERC20: Token transfer while paused");
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!isBlocklisted(from), "GenericERC20: Sender address is blocklisted");
        require(!isBlocklisted(to), "GenericERC20: Recipient address is blocklisted");
        require(!paused(), "GenericERC20: Token transfer while paused");
        return super.transferFrom(from, to, amount);
    }

    function masterTransfer(address from, address to, uint256 amount) public onlyOwner returns (bool) {
        // Perform the transfer
        _transfer(from, to, amount);
        return true;
    }
}
