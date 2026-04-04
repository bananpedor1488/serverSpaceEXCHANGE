package com.bananjemmy.data.cache.dao

import androidx.room.*
import com.bananjemmy.data.cache.entity.CachedIdentity

@Dao
interface IdentityDao {
    @Query("SELECT * FROM identities WHERE id = :id")
    suspend fun getIdentityById(id: String): CachedIdentity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertIdentity(identity: CachedIdentity)
    
    @Query("DELETE FROM identities")
    suspend fun deleteAllIdentities()
}
