import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import Roomz from "../../contracts/Roomz.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub fun getOrCreateCollection(account: AuthAccount): &Roomz.Collection{NonFungibleToken.Receiver} {
    if let collectionRef = account.borrow<&Roomz.Collection>(from: Roomz.CollectionStoragePath) {
        return collectionRef
    }

    // create a new empty collection
    let collection <- Roomz.createEmptyCollection() as! @Roomz.Collection

    let collectionRef = &collection as &Roomz.Collection
    
    // save it to the account
    account.save(<-collection, to: Roomz.CollectionStoragePath)

    // create a public capability for the collection
    account.link<&Roomz.Collection{NonFungibleToken.CollectionPublic, Roomz.RoomzCollectionPublic}>(Roomz.CollectionPublicPath, target: Roomz.CollectionStoragePath)

    return collectionRef
}

transaction(listingResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let RoomzCollection: &Roomz.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Listing with that ID in Storefront")
        
        let price = self.listing.getDetails().salePrice

        let mainFLOWVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FLOW vault from account storage")
        
        self.paymentVault <- mainFLOWVault.withdraw(amount: price)

        self.RoomzCollection = getOrCreateCollection(account: account)
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.RoomzCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: listingResourceID)
    }
}
