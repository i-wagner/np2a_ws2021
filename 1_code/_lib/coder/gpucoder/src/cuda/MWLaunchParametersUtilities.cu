/* Copyright 2017-2018 The MathWorks, Inc. */
#include "MWLaunchParametersUtilities.hpp"



bool mwApplyLaunchParameters(double numberOfThreads,
                             const dim3 *ingrid,const dim3 *inblock,
                             dim3 *outgrid, dim3 *outblock,
                           MW_LAUNCH_UNSIGNED_TYPE MAX_THREADS_PER_BLOCK,
                           MW_LAUNCH_UNSIGNED_TYPE MAX_BLOCKS_PER_GRID_DIM) {

    //if number of iterations are zero or less, return false
    if ( numberOfThreads <= 0.0 )
    {
        mwResetDim3ToZeros(outgrid);
        mwResetDim3ToZeros(outblock);
        return false;
    }

    //if input dims are not valid, use default computation.
    if ( !mwValidDim3(ingrid)  || !mwValidDim3(inblock) || !mwWithBlockSizeLimits(inblock))
        return mwGetLaunchParameters(numberOfThreads, outgrid, outblock, MAX_THREADS_PER_BLOCK, MAX_BLOCKS_PER_GRID_DIM);

    *outgrid = *ingrid;
    *outblock = *inblock;
    mwWrapToMultipleOf32(outblock);
    return true;
}

bool mwGetLaunchParameters(double numberOfThreads,
                           dim3 *grid, dim3 *block,
                           MW_LAUNCH_UNSIGNED_TYPE MAX_THREADS_PER_BLOCK,
                           MW_LAUNCH_UNSIGNED_TYPE MAX_BLOCKS_PER_GRID_DIM) {

    if ( numberOfThreads <= 0.0 )
    {
        mwResetDim3ToZeros(grid);
        mwResetDim3ToZeros(block);
        return false;
    }

    if ( numberOfThreads < (double)( MAX_THREADS_PER_BLOCK * MAX_BLOCKS_PER_GRID_DIM) ) {

        return mwGetLaunchParameters1D(numberOfThreads,
                                       grid, block,
                                       MAX_THREADS_PER_BLOCK,
                                       MAX_BLOCKS_PER_GRID_DIM);
    }

    if ( numberOfThreads <= static_cast<double>(MAX_THREADS_PER_BLOCK * (MAX_BLOCKS_PER_GRID_DIM * MAX_BLOCKS_PER_GRID_DIM))) {

        return  mwGetLaunchParameters2D(numberOfThreads,
                                        grid, block,
                                        MAX_THREADS_PER_BLOCK,
                                        MAX_BLOCKS_PER_GRID_DIM);
    }

    return mwGetLaunchParameters3D(numberOfThreads,
                                   grid,
                                   block,
                                   MAX_THREADS_PER_BLOCK,
                                   MAX_BLOCKS_PER_GRID_DIM);
    
}

bool mwGetLaunchParameters1D(double numberOfThreads,
                             dim3 *grid, dim3 *block,
                             MW_LAUNCH_UNSIGNED_TYPE MAX_THREADS_PER_BLOCK,
                             MW_LAUNCH_UNSIGNED_TYPE MAX_BLOCKS_PER_GRID_DIM) {

    MW_LAUNCH_UNSIGNED_TYPE x ;
    mwResetDim3(grid);
    mwResetDim3(block);
    
    if ( numberOfThreads <= (double)(512*MAX_BLOCKS_PER_GRID_DIM)) {

        if ( numberOfThreads <= (double) 512)
            x = (MW_LAUNCH_UNSIGNED_TYPE) numberOfThreads;
        else
            x = 512ul;
    }
    else
    {
        x = MAX_THREADS_PER_BLOCK ;
    }
    
    x = mwRoundToMultipleOf32(x);
    block->x  = x;
    grid->x  = (unsigned long int)  ceil(((double)numberOfThreads) / ((double) x));
                     
    return mwValidDim3(block) && mwValidDim3(grid);
    
}


bool mwGetLaunchParameters2D(double numberOfThreads, dim3 *grid, dim3 *block, MW_LAUNCH_UNSIGNED_TYPE MAX_THREADS_PER_BLOCK, MW_LAUNCH_UNSIGNED_TYPE MAX_BLOCKS_PER_GRID_DIM) {

    mwResetDim3(grid);
    mwResetDim3(block);

    block->x = 32;
    block->y = 32;
    block->z = 1;
      
    unsigned long int numBlocksPerDim = (unsigned long int)(
        ceil(sqrt(static_cast<double>(numberOfThreads)/1024)));
    grid->x = numBlocksPerDim;
    grid->y = numBlocksPerDim;
    grid->z =  1;
    
    return mwValidDim3(block) && mwValidDim3(grid);
}

bool mwGetLaunchParameters3D(double numberOfThreads, dim3 *grid, dim3 *block, MW_LAUNCH_UNSIGNED_TYPE MAX_THREADS_PER_BLOCK, MW_LAUNCH_UNSIGNED_TYPE MAX_BLOCKS_PER_GRID_DIM) {

    mwResetDim3(grid);
    mwResetDim3(block);

    numberOfThreads = numberOfThreads < (double) MAX_THREADS_PER_BLOCK * (double) MAX_BLOCKS_PER_GRID_DIM ? numberOfThreads : (double) MAX_THREADS_PER_BLOCK * (double) MAX_BLOCKS_PER_GRID_DIM; 

    block->x = 32;
    block->y = 32;
    block->z = 1;


    unsigned long int numBlocksPerDim = (unsigned long int)(
        ceil(cbrt(static_cast<double>(numberOfThreads)/1024)));
    grid->x = numBlocksPerDim;
    grid->y = numBlocksPerDim;
    grid->z =  numBlocksPerDim;

    return mwValidDim3(block) && mwValidDim3(block);

}


double mwTotalThreads(const dim3 *obj) {
    return static_cast<double>(obj->x) * static_cast<double>(obj->y) * static_cast<double>(obj->z);
}
bool mwValidDim3(const dim3 *obj) {

    return obj->x > 0  && obj->y > 0 && obj->z > 0 ;
}

void mwResetDim3(dim3 *obj) {
    obj->x = 1;
    obj->y = 1;
    obj->z = 1;
}


void mwResetDim3ToZeros(dim3 *obj) {
    obj->x = 0;
    obj->y = 0;
    obj->z = 0;
}


MW_LAUNCH_UNSIGNED_TYPE mwRoundToMultipleOf32(MW_LAUNCH_UNSIGNED_TYPE val) {
    return ((val + 31ul) / 32ul) * 32ul;
}

void mwWrapToMultipleOf32(dim3 *in) {

    unsigned int total = mwTotalThreads(in);

    if(total % 32u == 0 )
        return;

    unsigned int newTotal = mwRoundToMultipleOf32(total);
    in->z = 1;
    in->y = newTotal/32;
    in->x = 32;
}

bool mwWithBlockSizeLimits(const dim3 *in) {

    unsigned int total = mwTotalThreads(in);
    return total <= 1024U;
}
