import Roomz from "../../contracts/Roomz.cdc"

// This scripts returns the number of Roomz currently in existence.

pub fun main(): UInt64 {    
    return Roomz.totalSupply
}
