import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import Roomz from "../../contracts/Roomz.cdc"

// This script returns the size of an account's Roomz collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(Roomz.CollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}
