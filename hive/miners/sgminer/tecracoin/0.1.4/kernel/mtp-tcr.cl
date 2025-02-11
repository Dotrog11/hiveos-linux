
/**
* MTP
* djm34 2017-2018
* krnlx 2018
* djm34 2019
**/
#pragma OPENCL EXTENSION cl_khr_subgroups : enable
#define NVIDIA_GPU 0
#ifdef cl_nv_pragma_unroll
#define NVIDIA
#undef NVIDIA_GPU
#define NVIDIA_GPU 1
#endif
#define NVIDIA_GPU 0

#pragma OPENCL EXTENSION cl_clang_storage_class_specifiers : enable
typedef unsigned long uint64_t;
typedef uint uint32_t;

#define ARGON2_SYNC_POINTS 4
#define argon_outlen 32
#define argon_timecost 1
#define argon_memcost 4*1024*1024 // *1024 //32*1024*2 //1024*256*1 //2Gb
#define argon_lanes 4
#define argon_threads 1
#define argon_hashlen 80
#define argon_version 19
#define argon_type 0 // argon2d
#define argon_pwdlen 80 // hash and salt lenght
#define argon_default_flags 0 // hmm not sure
#define argon_segment_length argon_memcost/(argon_lanes * ARGON2_SYNC_POINTS)
#define argon_lane_length argon_segment_length * ARGON2_SYNC_POINTS
#define TREE_LEVELS 20
#define ELEM_MAX 2048
#define gpu_thread 2
#define gpu_shared 128
#define kernel1_thread 64
#define mtp_L 16
#define TPB52 32
#define TPB30 160
#define TPB20 160
#define _HIDWORD(x) as_uint2(x).y
#define _LODWORD(x) as_uint2(x).x
#define UINT64_C(x)  (x ## UL)
#define devectorize(x) as_ulong(x)
#define vectorize(x) as_uint2(x)
#define SWAP32(x) as_ulong(as_uint2(x).s10)
static __constant const uint2 blakeInit[8] =
{
	(0xf2bdc948U, 0x6a09e667U),
	(0x84caa73bU, 0xbb67ae85U),
	(0xfe94f82bU, 0x3c6ef372U),
	(0x5f1d36f1U, 0xa54ff53aU),
	(0xade682d1U, 0x510e527fU),
	(0x2b3e6c1fU, 0x9b05688cU),
	(0xfb41bd6bU, 0x1f83d9abU),
	(0x137e2179U, 0x5be0cd19U)
};

__constant const uint2 blakeFinal[8] =
{
	(0xf2bdc928U, 0x6a09e667U),
	(0x84caa73bU, 0xbb67ae85U),
	(0xfe94f82bU, 0x3c6ef372U),
	(0x5f1d36f1U, 0xa54ff53aU),
	(0xade682d1U, 0x510e527fU),
	(0x2b3e6c1fU, 0x9b05688cU),
	(0xfb41bd6bU, 0x1f83d9abU),
	(0x137e2179U, 0x5be0cd19U)
};

__constant const uint2 blakeIV[8] =
{
	(0xf3bcc908U, 0x6a09e667U),
	(0x84caa73bU, 0xbb67ae85U),
	(0xfe94f82bU, 0x3c6ef372U),
	(0x5f1d36f1U, 0xa54ff53aU),
	(0xade682d1U, 0x510e527fU),
	(0x2b3e6c1fU, 0x9b05688cU),
	(0xfb41bd6bU, 0x1f83d9abU),
	(0x137e2179U, 0x5be0cd19U)
};

__constant const uint2 blakeInit2[8] =
{
	(0xf2bdc918U, 0x6a09e667U),
	(0x84caa73bU, 0xbb67ae85U),
	(0xfe94f82bU, 0x3c6ef372U),
	(0x5f1d36f1U, 0xa54ff53aU),
	(0xade682d1U, 0x510e527fU),
	(0x2b3e6c1fU, 0x9b05688cU),
	(0xfb41bd6bU, 0x1f83d9abU),
	(0x137e2179U, 0x5be0cd19U)
};


__constant static const uchar blake2b_sigma[12][16] =
{
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 } ,
	{ 14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3 } ,
	{ 11,  8, 12,  0,  5,  2, 15, 13, 10, 14,  3,  6,  7,  1,  9,  4 } ,
	{ 7,  9,  3,  1, 13, 12, 11, 14,  2,  6,  5, 10,  4,  0, 15,  8 } ,
	{ 9,  0,  5,  7,  2,  4, 10, 15, 14,  1, 11, 12,  6,  8,  3, 13 } ,
	{ 2, 12,  6, 10,  0, 11,  8,  3,  4, 13,  7,  5, 15, 14,  1,  9 } ,
	{ 12,  5,  1, 15, 14, 13,  4, 10,  0,  7,  6,  3,  9,  2,  8, 11 } ,
	{ 13, 11,  7, 14, 12,  1,  3,  9,  5,  0, 15,  4,  8,  6,  2, 10 } ,
	{ 6, 15, 14,  9, 11,  3,  0,  8, 12,  2, 13,  7,  1,  4, 10,  5 } ,
	{ 10,  2,  8,  4,  7,  6,  1,  5, 15, 11,  9, 14,  3, 12, 13 , 0 } ,
	{ 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15 } ,
	{ 14, 10,  4,  8,  9, 15, 13,  6,  1, 12,  0,  2, 11,  7,  5,  3 }
};


#define SPH_ROTL64(x, n) rotate(as_ulong(x), (n) & 0xFFFFFFFFFFFFFFFFUL)
#define SPH_ROTR64(x, n) SPH_ROTL64(x, (64 - (n)))




#if NVIDIA_GPU == 1
static inline uint64_t ROTR64X(const uint64_t x2, const int y) {
	return rotate(x2, (ulong)(64 - y));
}
#else 
static inline uint64_t ROTR64X(const uint64_t x2, const int y) {
	uint2 x = as_uint2(x2);
	if (y < 32) return(as_ulong(amd_bitalign(x.s10, x, y)));
	else return(as_ulong(amd_bitalign(x, x.s10, (y - 32))));
}
#endif




static inline uint2 ROR2(uint2 v, unsigned a) {
	uint2 result;
	unsigned n = 64 - a;
	if (n == 32) { return (uint2)(v.y, v.x); }
	if (n < 32) {
		result.y = ((v.y << (n)) | (v.x >> (32 - n)));
		result.x = ((v.x << (n)) | (v.y >> (32 - n)));
	}
	else {
		result.y = ((v.x << (n - 32)) | (v.y >> (64 - n)));
		result.x = ((v.y << (n - 32)) | (v.x >> (64 - n)));
	}
	return result;
}
static inline uint2 ror2l(uint2 v, unsigned a) {
	uint2 result;
	result.y = ((v.x << (32 - a)) | (v.y >> (a)));
	result.x = ((v.y << (32 - a)) | (v.x >> (a)));
	return result;
}
static inline uint2 ror2r(uint2 v, unsigned a) {
	uint2 result;
	result.y = ((v.y << (64 - a)) | (v.x >> (a - 32)));
	result.x = ((v.x << (64 - a)) | (v.y >> (a - 32)));
	return result;
}


static inline uint2 eorswap32(uint2 u, uint2 v)
{
	uint2 result;
	result.y = u.x ^ v.x;
	result.x = u.y ^ v.y;
	return result;
}

static inline uint64_t eorswap64(uint64_t u, uint64_t v)
{
	return ROTR64X(u^v, 32);
}



#define GS(a,b,c,d,e,f) \
   { \
     v[a] +=   v[b] + m[e]; \
     v[d] = SWAP32(v[d] ^ v[a]); \
     v[c] += v[d]; \
     v[b] = ROTR64X(v[b] ^ v[c], 24); \
     v[a] += v[b] + m[f]; \
     v[d] = ROTR64X(v[d] ^ v[a], 16); \
     v[c] += v[d]; \
     v[b] = ROTR64X(v[b] ^ v[c], 63); \
  } 



static inline  int blake2b_compress4xv2(uint64_t *hash, const uint64_t *hzcash, const uint64_t *block, const uint32_t len, int last)
{
	uint64_t m[16];
	uint64_t v[16];

	const uint64_t blakeIV_[8] = {
		0x6a09e667f3bcc908UL,
		0xbb67ae8584caa73bUL,
		0x3c6ef372fe94f82bUL,
		0xa54ff53a5f1d36f1UL,
		0x510e527fade682d1UL,
		0x9b05688c2b3e6c1fUL,
		0x1f83d9abfb41bd6bUL,
		0x5be0cd19137e2179UL
	};

	for (int i = 0; i < 16; ++i)
		m[i] = block[i];

	for (int i = 0; i < 8; ++i)
		v[i] = hzcash[i];


	v[8] = blakeIV_[0];
	v[9] = blakeIV_[1];
	v[10] = blakeIV_[2];
	v[11] = blakeIV_[3];
	v[12] = blakeIV_[4];
	v[12] ^= len;
	v[13] = blakeIV_[5];
	v[14] = last ? ~blakeIV_[6] : blakeIV_[6];
	v[15] = blakeIV_[7];

/*
#define G(r,i,a,b,c,d) \
   { \
     v[a] +=   v[b] + (m[blake2b_sigma[r][2*i+0]]); \
     v[d] = SWAP32(v[d] ^ v[a]); \
     v[c] += v[d]; \
     v[b] = ROTR64X(v[b] ^ v[c], 24); \
     v[a] += v[b] + (m[blake2b_sigma[r][2*i+1]]); \
     v[d] = ROTR64X(v[d] ^ v[a], 16); \
     v[c] += v[d]; \
     v[b] = ROTR64X(v[b] ^ v[c], 63); \
  } 
*/
#define G(r,i,a,b,c,d) \
   { \
     v[a] +=   v[b] + (m[blake2b_sigma[r][2*i+0]]); \
     v[d] = SWAP32(v[d] ^ v[a]); \
     v[c] += v[d]; \
	 v[b] ^=v[c]; \
     v[b] = as_ulong(amd_bitalign(as_uint2(v[b]).s10, as_uint2(v[b]), (24))); \
     v[a] += v[b] + (m[blake2b_sigma[r][2*i+1]]); \
	 v[d] ^=v[a]; \
     v[d] = as_ulong(amd_bitalign(as_uint2(v[d]).s10, as_uint2(v[d]), (16))); \
     v[c] += v[d]; \
	 v[b] ^=v[c]; \
     v[b] = as_ulong(amd_bitalign(as_uint2(v[b]), as_uint2(v[b]).s10, (31))); \
  } 

#define ROUND(r)  \
  { \
    G(r,0, 0,4,8,12); \
    G(r,1, 1,5,9,13); \
    G(r,2, 2,6,10,14); \
    G(r,3, 3,7,11,15); \
    G(r,4, 0,5,10,15); \
    G(r,5, 1,6,11,12); \
    G(r,6, 2,7,8,13); \
    G(r,7, 3,4,9,14); \
  } 

	ROUND(0);
	ROUND(1);
	ROUND(2);
	ROUND(3);

	for (int i = 0; i < 8; ++i)
		hash[i] = hzcash[i] ^ v[i] ^ v[i + 8];


#undef G
#undef ROUND
	return 0;
}

#define SUBDIV 2
#define SUBDIV2 256 //8
 
#if PLATFORM == OPENCL_PLATFORM_NVIDIA && COMPUTE >= 35
static unsigned lane_id()
{
	unsigned ret;
	asm volatile ("mov.u32 %0, %laneid;" : "=r"(ret));
	return ret;
}

static unsigned warp_id()
{
	// this is not equal to threadIdx.x / 32
	unsigned ret;
	asm volatile ("mov.u32 %0, %warpid;" : "=r"(ret));
	return ret;
}
#endif


#ifdef WORKSIZE
#define TPB_MTP WORKSIZE
#else 
#define TPB_MTP 64
#endif


__attribute__((reqd_work_group_size(TPB_MTP, 1, 1)))
__kernel void mtp_yloop(__global unsigned int* pData, __global const ulong8  * /*__restrict__*/ DBlock, __global const ulong8  * /*__restrict__*/ DBlock2,
	__global uint4 * Elements, __global uint32_t * __restrict__ SmallestNonce, uint pTarget)
{
#define G(r,i,a,b,c,d) \
   { \
     v[a] +=   v[b] + (m[blake2b_sigma[r][2*i+0]]); \
     v[d] = SWAP32(v[d] ^ v[a]); \
     v[c] += v[d]; \
	 v[b] ^=v[c]; \
     v[b] = as_ulong(amd_bitalign(as_uint2(v[b]).s10, as_uint2(v[b]), (24))); \
     v[a] += v[b] + (m[blake2b_sigma[r][2*i+1]]); \
	 v[d] ^=v[a]; \
     v[d] = as_ulong(amd_bitalign(as_uint2(v[d]).s10, as_uint2(v[d]), (16))); \
     v[c] += v[d]; \
	 v[b] ^=v[c]; \
     v[b] = as_ulong(amd_bitalign(as_uint2(v[b]), as_uint2(v[b]).s10, (31))); \
  } 
#define ROUND(r)  \
  { \
    G(r,0, 0,4,8,12); \
    G(r,1, 1,5,9,13); \
    G(r,2, 2,6,10,14); \
    G(r,3, 3,7,11,15); \
    G(r,4, 0,5,10,15); \
    G(r,5, 1,6,11,12); \
    G(r,6, 2,7,8,13); \
    G(r,7, 3,4,9,14); \
  } 
//uint32_t event_thread = get_global_id(0) - get_global_offset(0);
	//if (event_thread<128) 
	//	printf("get_sub_group_size %d get_sub_group_local_id %d  get_num_sub_groups %d\n", get_sub_group_size(), get_sub_group_local_id(), get_num_sub_groups());

	uint64_t m[16] = { 0 };
	uint64_t v[16];
	uint32_t NonceIterator = get_global_id(0);
	uint TheIndex[2];
	int lane = get_local_id(0) % SUBDIV2;
	int warp = get_local_id(0) / SUBDIV2;;//warp_id();
										  //	int lane = get_sub_group_local_id();
										  //	int warp = get_sub_group_id();

	int indice = 2*lane; //(lane%SUBDIV + SUBDIV*(lane / SUBDIV)) * (SUBDIV );
	__local  ulong8 far[TPB_MTP / SUBDIV2][SUBDIV2 * SUBDIV];

	const uint32_t half_memcost = 2 * 1024 * 1024;

	const uint64_t lblakeFinal[8] =
	{
		0x6a09e667f2bdc928UL,
		0xbb67ae8584caa73bUL,
		0x3c6ef372fe94f82bUL,
		0xa54ff53a5f1d36f1UL,
		0x510e527fade682d1UL,
		0x9b05688c2b3e6c1fUL,
		0x1f83d9abfb41bd6bUL,
		0x5be0cd19137e2179UL,
	};
	const uint64_t blakeIV_[8] = {
		0x6a09e667f3bcc908UL,
		0xbb67ae8584caa73bUL,
		0x3c6ef372fe94f82bUL,
		0xa54ff53a5f1d36f1UL,
		0x510e527fade682d1UL,
		0x9b05688c2b3e6c1fUL,
		0x1f83d9abfb41bd6bUL,
		0x5be0cd19137e2179UL
	};


	ulong4 YLocal;
	

	//	ulong8 DataChunk[2] = { 0 };

	((uint8 *)m)[0] = ((__global uint8 *)pData)[0];
	((uint8 *)m)[1] = ((__global uint8 *)pData)[1];

	((uint4*)m)[4] = ((__global uint4*)pData)[4];
	((uint4*)m)[5] = ((__global uint4*)Elements)[0];

	((uint16*)m)[1].hi.s0 = NonceIterator;

	//	blake2b_compress2_256((uint64_t*)&YLocal, lblakeFinal, (uint64_t*)DataChunk, 100);


	((ulong8*)v)[0] = ((ulong8*)lblakeFinal)[0];
	v[8] = blakeIV_[0];
	v[9] = blakeIV_[1];
	v[10] = blakeIV_[2];
	v[11] = blakeIV_[3];
	v[12] = blakeIV_[4];
	v[12] ^= 100;
	v[13] = blakeIV_[5];
	v[14] = ~blakeIV_[6];
	v[15] = blakeIV_[7];

#pragma unroll 
	for (int i = 0; i<12; i++)	ROUND(i);

	YLocal = ((ulong4*)lblakeFinal)[0] ^ ((ulong4*)v)[0] ^ ((ulong4*)v)[2];



#pragma unroll mtp_L
	for (int j = 0; j < mtp_L; j++)
	{

		uint YLocs0 = (as_uint8(YLocal).s0 & 0x3FFFFF);
		uint32_t len = 0;

		/*
		ulong8 DataTmp;
		DataTmp.s0 = lblakeFinal[0];
		DataTmp.s1 = lblakeFinal[1];
		DataTmp.s2 = lblakeFinal[2];
		DataTmp.s3 = lblakeFinal[3];
		DataTmp.s4 = lblakeFinal[4];
		DataTmp.s5 = lblakeFinal[5];
		DataTmp.s6 = lblakeFinal[6];
		DataTmp.s7 = lblakeFinal[7];
		*/
		ulong8 DataTmp = ((ulong8*)lblakeFinal)[0];
		//		ulong8 DataTmp = vload8(0U,lblakeFinal);
#pragma unroll 
		for (int i = 0; i < 4; ++i)
			m[i] = ((uint64_t*)&YLocal)[i];


#if defined(__Polaris__) || defined(__Ellesmere__)
		TheIndex[lane % 2] = YLocs0;
		TheIndex[(lane + 1) % 2] = sub_group_broadcast(YLocs0, (lane + 1) % 2 + SUBDIV * (lane / SUBDIV));

#else 
		int ind = SUBDIV * (get_sub_group_local_id() / SUBDIV);
		TheIndex[0] = sub_group_broadcast(YLocs0, ind);
		TheIndex[1] = sub_group_broadcast(YLocs0, 1 + ind);
#endif

		#pragma unroll 
		for (int i = 0; i < 9; i++) {
			int last = (i == 8);
			//				int indice = (lane%SUBDIV + SUBDIV*(lane / SUBDIV)) * (SUBDIV + SHR_OFF);
			len += last ? 32 : 128;
			//			len += (i<8) ? 128 : 32;

				if (i<8) {
			#pragma unroll 
			for (int t = 0; t<SUBDIV; t++) {

					__global const ulong8 * /*__restrict__*/ farP = (TheIndex[t]<half_memcost) ? &DBlock[TheIndex[t] * 16 + 2 * i]
						: &DBlock2[(TheIndex[t] - half_memcost) * 16 + 2 * i];

					prefetch(&farP[lane%SUBDIV], 1);

					far[warp][lane%SUBDIV + (t + SUBDIV*(lane / SUBDIV)) * (SUBDIV )] = farP[lane%SUBDIV];
//					far[warp][2*t + lane%2 + 4*(lane/2)]= farP[lane%SUBDIV];
//					far[warp][2*t + 2*(lane/2) + lane] = farP[lane%SUBDIV];

//					far[warp][256*t + lane] = farP[lane%SUBDIV];
					//					far[warp][(t + SUBDIV*(lane / SUBDIV))][lane%SUBDIV] = farP[lane%SUBDIV];
				}
				//				sub_group_barrier(CLK_LOCAL_MEM_FENCE);
			}

			vstore4(last ? (ulong4)(0, 0, 0, 0) : far[warp][indice].lo, 1, m);
			vstore4(last ? (ulong4)(0, 0, 0, 0) : far[warp][indice].hi, 2, m);
			vstore4(last ? (ulong4)(0, 0, 0, 0) : far[warp][1 + indice].lo, 3, m);


			/*
			vstore8(DataTmp, 0, v);


			((ulong4*)m)[1] = (last) ? (ulong4)(0, 0, 0, 0) : far[warp][indice].lo;
			((ulong4*)m)[2] = (last) ? (ulong4)(0, 0, 0, 0) : far[warp][indice].hi;
			((ulong4*)m)[3] = (last) ? (ulong4)(0, 0, 0, 0) : far[warp][1 + indice].lo;
			*/

			((ulong8*)v)[0] = DataTmp;
			v[8] = blakeIV_[0];
			v[9] = blakeIV_[1];
			v[10] = blakeIV_[2];
			v[11] = blakeIV_[3];
			v[12] = blakeIV_[4];
			v[12] ^= len;
			v[13] = blakeIV_[5];
			v[14] = (i<8) ? blakeIV_[6] : ~blakeIV_[6];
			v[15] = blakeIV_[7];

#pragma unroll 
			for (int k = 0; k<12; k++)	ROUND(k);

			DataTmp ^= ((ulong8*)v)[0] ^ ((ulong8*)v)[1];


			//if (last) continue;
			//			((ulong4*)m)[0] = /*(last) ? (ulong4)(0, 0, 0, 0) :*/ far[warp][1+ indice].hi;
			vstore4(far[warp][1 + indice].hi, 0, m);

		}



		YLocal = DataTmp.lo;

	}

	if (as_uint8(YLocal).s7 <= pTarget)
	{

		SmallestNonce[atomic_inc(SmallestNonce + 0xFF)] = NonceIterator;
	}
#undef G
#undef ROUND
}




__attribute__((reqd_work_group_size(TPB_MTP, 1, 1)))
__kernel void mtp_yloop_old(__global unsigned int* pData, __global const ulong8  * /*__restrict__*/ DBlock, __global const ulong8  * /*__restrict__*/ DBlock2,
	__global uint4 * Elements, __global uint32_t * __restrict__ SmallestNonce, uint pTarget)
{
#define G(r,i,a,b,c,d) \
   { \
     v[a] +=   v[b] + (m[blake2b_sigma[r][2*i+0]]); \
     v[d] = SWAP32(v[d] ^ v[a]); \
     v[c] += v[d]; \
	 v[b] ^=v[c]; \
     v[b] = as_ulong(amd_bitalign(as_uint2(v[b]).s10, as_uint2(v[b]), (24))); \
     v[a] += v[b] + (m[blake2b_sigma[r][2*i+1]]); \
	 v[d] ^=v[a]; \
     v[d] = as_ulong(amd_bitalign(as_uint2(v[d]).s10, as_uint2(v[d]), (16))); \
     v[c] += v[d]; \
	 v[b] ^=v[c]; \
     v[b] = as_ulong(amd_bitalign(as_uint2(v[b]), as_uint2(v[b]).s10, (31))); \
  } 
#define ROUND(r)  \
  { \
    G(r,0, 0,4,8,12); \
    G(r,1, 1,5,9,13); \
    G(r,2, 2,6,10,14); \
    G(r,3, 3,7,11,15); \
    G(r,4, 0,5,10,15); \
    G(r,5, 1,6,11,12); \
    G(r,6, 2,7,8,13); \
    G(r,7, 3,4,9,14); \
  } 
//	uint32_t event_thread = get_global_id(0) - get_global_offset(0);
//if (event_thread<128) 
//	printf("get_sub_group_size %d get_sub_group_local_id %d  get_num_sub_groups %d\n", get_sub_group_size(), get_sub_group_local_id(), get_num_sub_groups());

	uint64_t m[16] = { 0 };
	uint64_t v[16];
	uint32_t NonceIterator = get_global_id(0);
	uint TheIndex[2];
	int lane = get_local_id(0) % SUBDIV2;
	int warp = get_local_id(0) / SUBDIV2;;//warp_id();
//	int lane = get_sub_group_local_id();
//	int warp = get_sub_group_id();

	int indice = (lane%SUBDIV + SUBDIV*(lane / SUBDIV)) * (SUBDIV);
	__local  ulong8 far[TPB_MTP / SUBDIV2][SUBDIV2 * (SUBDIV )];

	const uint32_t half_memcost = 2 * 1024 * 1024;

	const uint64_t lblakeFinal[8] =
	{
		0x6a09e667f2bdc928UL,
		0xbb67ae8584caa73bUL,
		0x3c6ef372fe94f82bUL,
		0xa54ff53a5f1d36f1UL,
		0x510e527fade682d1UL,
		0x9b05688c2b3e6c1fUL,
		0x1f83d9abfb41bd6bUL,
		0x5be0cd19137e2179UL,
	};
	const uint64_t blakeIV_[8] = {
		0x6a09e667f3bcc908UL,
		0xbb67ae8584caa73bUL,
		0x3c6ef372fe94f82bUL,
		0xa54ff53a5f1d36f1UL,
		0x510e527fade682d1UL,
		0x9b05688c2b3e6c1fUL,
		0x1f83d9abfb41bd6bUL,
		0x5be0cd19137e2179UL
	};


	ulong4 YLocal;


	//	ulong8 DataChunk[2] = { 0 };

	((uint8 *)m)[0] = ((__global uint8 *)pData)[0];
	((uint8 *)m)[1] = ((__global uint8 *)pData)[1];

	((uint4*)m)[4] = ((__global uint4*)pData)[4];
	((uint4*)m)[5] = ((__global uint4*)Elements)[0];

	((uint16*)m)[1].hi.s0 = NonceIterator;

	//	blake2b_compress2_256((uint64_t*)&YLocal, lblakeFinal, (uint64_t*)DataChunk, 100);


	((ulong8*)v)[0] = ((ulong8*)lblakeFinal)[0];
	v[8] = blakeIV_[0];
	v[9] = blakeIV_[1];
	v[10] = blakeIV_[2];
	v[11] = blakeIV_[3];
	v[12] = blakeIV_[4];
	v[12] ^= 100;
	v[13] = blakeIV_[5];
	v[14] = ~blakeIV_[6];
	v[15] = blakeIV_[7];

	#pragma unroll 
	for (int i = 0; i<12; i++)	ROUND(i);

	YLocal = ((ulong4*)lblakeFinal)[0] ^ ((ulong4*)v)[0] ^ ((ulong4*)v)[2];



	#pragma unroll mtp_L
	for (int j = 0; j < mtp_L; j++)
	{


		uint32_t len = 0;

/*
		ulong8 DataTmp;
		DataTmp.s0 = lblakeFinal[0];
		DataTmp.s1 = lblakeFinal[1];
		DataTmp.s2 = lblakeFinal[2];
		DataTmp.s3 = lblakeFinal[3];
		DataTmp.s4 = lblakeFinal[4];
		DataTmp.s5 = lblakeFinal[5];
		DataTmp.s6 = lblakeFinal[6];
		DataTmp.s7 = lblakeFinal[7];
*/
		ulong8 DataTmp = ((ulong8*)lblakeFinal)[0];
		//		ulong8 DataTmp = vload8(0U,lblakeFinal);
		#pragma unroll 
		for (int i = 0; i < 4; ++i)
			m[i] = ((uint64_t*)&YLocal)[i];


#if defined(__Polaris__) || defined(__Ellesmere__)
		TheIndex[lane % 2] = as_uint8(YLocal).s0 & 0x3FFFFF;
		TheIndex[(lane + 1) % 2] = sub_group_broadcast((as_uint8(YLocal).s0 & 0x3FFFFF), (lane + 1) % 2 + SUBDIV * (lane / SUBDIV));

#else 
		TheIndex[0] = sub_group_broadcast((as_uint8(YLocal).s0 & 0x3FFFFF), 0 + SUBDIV * (get_sub_group_local_id() / SUBDIV));
		TheIndex[1] = sub_group_broadcast((as_uint8(YLocal).s0 & 0x3FFFFF), 1 + SUBDIV * (get_sub_group_local_id() / SUBDIV));
#endif

		#pragma unroll 
		for (int i = 0; i < 9; i++) {
			int last = (i == 8);
			//				int indice = (lane%SUBDIV + SUBDIV*(lane / SUBDIV)) * (SUBDIV + SHR_OFF);
			len += last ? 32 : 128;
//			len += (i<8) ? 128 : 32;


				#pragma unroll 
				for (int t = 0; t<SUBDIV ; t++) {
		if (i<8) {
					__global const ulong8 * /*__restrict__*/ farP = (TheIndex[t]<half_memcost) ? &DBlock[TheIndex[t] * 16 + 2 * i]
						: &DBlock2[(TheIndex[t] - half_memcost) * 16 + 2 * i];

					//					__global const ulong8 * __restrict__ farP = (i<4) ? &DBlock[test * 2 + 2 * i * argon_memcost]
					//						: &DBlock2[test * 2 + 2 * (i - 4) * argon_memcost];			
					prefetch(&farP[lane%SUBDIV], 1);
				
					far[warp][lane%SUBDIV + (t + SUBDIV*(lane / SUBDIV)) * (SUBDIV)] = farP[lane%SUBDIV];
					//					far[warp][(t + SUBDIV*(lane / SUBDIV))][lane%SUBDIV] = farP[lane%SUBDIV];
				}
//				sub_group_barrier(CLK_LOCAL_MEM_FENCE);
		}



			vstore4(last ? (ulong4)(0, 0, 0, 0) : far[warp][indice].lo     , 1, m);
			vstore4(last ? (ulong4)(0, 0, 0, 0) : far[warp][indice].hi     , 2, m);
			vstore4(last ? (ulong4)(0, 0, 0, 0) : far[warp][1 + indice].lo , 3, m);
/*
			vstore8(DataTmp, 0, v);


						((ulong4*)m)[1] = (last) ? (ulong4)(0, 0, 0, 0) : far[warp][indice].lo;
						((ulong4*)m)[2] = (last) ? (ulong4)(0, 0, 0, 0) : far[warp][indice].hi;
						((ulong4*)m)[3] = (last) ? (ulong4)(0, 0, 0, 0) : far[warp][1 + indice].lo;
*/

			((ulong8*)v)[0] = DataTmp;
			v[8] = blakeIV_[0];
			v[9] = blakeIV_[1];
			v[10] = blakeIV_[2];
			v[11] = blakeIV_[3];
			v[12] = blakeIV_[4];
			v[12] ^= len;
			v[13] = blakeIV_[5];
			v[14] = (i<8) ? blakeIV_[6] : ~blakeIV_[6];
			v[15] = blakeIV_[7];

			#pragma unroll 
			for (int k = 0; k<12; k++)	ROUND(k);

			DataTmp ^= ((ulong8*)v)[0] ^ ((ulong8*)v)[1];


			//if (last) continue;
//			((ulong4*)m)[0] = /*(last) ? (ulong4)(0, 0, 0, 0) :*/ far[warp][1+ indice].hi;
			vstore4(far[warp][1 + indice].hi, 0, m);
			/////////////////////////////////////////////////////////////////////////////////////////////////////
		}



		YLocal = DataTmp.lo;

	}

	if (as_uint8(YLocal).s7 <= pTarget)
	{

		SmallestNonce[atomic_inc(SmallestNonce + 0xFF)] = NonceIterator;
	}
#undef G
#undef ROUND
}



static inline  uint32_t index_alpha(const uint32_t passs, const uint32_t slice, const uint32_t index,
	uint32_t pseudo_rand,
	int same_lane, const uint32_t ss, const uint32_t ss1) {

	uint32_t reference_area_size;
	uint64_t relative_position;
	uint32_t start_position, absolute_position;
	uint32_t lane_length = 1048576;
	uint32_t segment_length = 262144;
	uint32_t lanes = 4;

	if (0 == passs) {

		if (0 == slice) {
			reference_area_size = index - 1;
		}
		else {
			if (same_lane) {
				reference_area_size = ss + index - 1;
			}
			else {
				reference_area_size = ss - ((index == 0) ? 1 : 0);
			}
		}
	}
	else {
		if (same_lane) {
			reference_area_size = lane_length - segment_length + index - 1;
		}
		else {
			reference_area_size = lane_length - segment_length - ((index == 0) ? 1 : 0);
		}
	}

	relative_position = pseudo_rand;

	relative_position = (uint)((relative_position * relative_position) >> 32);

	relative_position = reference_area_size - 1 - (uint)((reference_area_size * relative_position) >> 32);

	start_position = 0;

	if (0 != passs)
		start_position = (slice == ARGON2_SYNC_POINTS - 1) ? 0 : (ss1);

	absolute_position = (start_position + relative_position) & 0xFFFFF;
	return absolute_position;
}

struct mem_blk {
	uint64_t v[128];
};


/*__device__ __forceinline__*/ // void copy_block(__local struct mem_blk *dst, __local const struct mem_blk *src) 

/*__device__ __forceinline__*/ uint64_t fBlaMka(uint64_t x, uint64_t y) {
	//	const uint64_t m = 0xFFFFFFFFUL;
	//	const uint64_t xy = ((uint64_t)_LODWORD(x) * (uint64_t)_LODWORD(y));
	const uint64_t xy = (ulong)((uint)(x & 0xFFFFFFFFUL)) * (ulong)((uint)(y & 0xFFFFFFFFUL));
	return x + y + 2 * xy;
}



static inline void fill_block_withIndex(__global const struct mem_blk *prev_block, __global const struct mem_blk *ref_block,
	__global struct mem_blk *next_block, int with_xor, uint32_t block_header[8], uint32_t index) {

	__local struct mem_blk blockR;
	__local struct mem_blk block_tmp;
	int tid = get_local_id(0);
	uint32_t TheIndex[2] = { 0,index };
	uint2 TheIndex2;
	TheIndex2.x = 0;
	TheIndex2.y = index;
	unsigned i;


#define GBLOCK(a, b, c, d)                                                     \
     {                                                                       \
        a = fBlaMka(a, b);                                                     \
        d = ROTR64X(d ^ a, 32);											       \
        c = fBlaMka(c, d);                                                     \
        b = ROTR64X(b ^ c, 24);                                                 \
        a = fBlaMka(a, b);                                                     \
        d = ROTR64X(d ^ a, 16);                                                 \
        c = fBlaMka(c, d);                                                     \
        b = ROTR64X(b ^ c, 63);                                                 \
    } 


	//	copy_block(blockR, ref_block);

	blockR.v[tid] = ref_block->v[tid];
	blockR.v[tid + 32] = ref_block->v[tid + 32];
	blockR.v[tid + 64] = ref_block->v[tid + 64];
	blockR.v[tid + 96] = ref_block->v[tid + 96];

//	((__local ulong4*)blockR.v)[tid] = ((__global ulong4*)ref_block->v)[tid];

	//	xor_block(blockR, prev_block);

	blockR.v[tid] ^= prev_block->v[tid];
	blockR.v[tid + 32] ^= prev_block->v[tid + 32];
	blockR.v[tid + 64] ^= prev_block->v[tid + 64];
	blockR.v[tid + 96] ^= prev_block->v[tid + 96];

//	((__local ulong4*)blockR.v)[tid] ^= ((__global ulong4*)prev_block->v)[tid];

	//	copy_block(block_tmp, blockR);

	block_tmp.v[tid] = blockR.v[tid];
	block_tmp.v[tid + 32] = blockR.v[tid + 32];
	block_tmp.v[tid + 64] = blockR.v[tid + 64];
	block_tmp.v[tid + 96] = blockR.v[tid + 96];

//	((__local ulong4*)block_tmp.v)[tid] = ((__local ulong4*)blockR.v)[tid];

	barrier(CLK_LOCAL_MEM_FENCE);

	if (!tid)
		blockR.v[14] = as_ulong(TheIndex2);



	__local uint32_t *bl = (__local uint32_t*)&blockR.v[16];

	if (!tid)
		for (int i = 0; i<8; i++)
			bl[i] = block_header[i];


	barrier(CLK_LOCAL_MEM_FENCE);

	{

		int i = tid;
		int y = (tid >> 2) << 4;
		int x = tid & 3;


		GBLOCK(blockR.v[y + x], blockR.v[y + 4 + x], blockR.v[y + 8 + x], blockR.v[y + 12 + x]);
		GBLOCK(blockR.v[y + x], blockR.v[y + 4 + ((1 + x) & 3)], blockR.v[y + 8 + ((2 + x) & 3)], blockR.v[y + 12 + ((3 + x) & 3)]);

	}
	barrier(CLK_LOCAL_MEM_FENCE);

	{

		int i = tid;
		int y = (tid >> 2) << 1;
		int x = tid & 3;
		int a = ((x) >> 1) * 16;
		int b = x & 1;

		int a1 = (((x + 1) & 3) >> 1) * 16;
		int b1 = (x + 1) & 1;

		int a2 = (((x + 2) & 3) >> 1) * 16;
		int b2 = (x + 2) & 1;

		int a3 = (((x + 3) & 3) >> 1) * 16;
		int b3 = (x + 3) & 1;

		GBLOCK(blockR.v[y + b + a], blockR.v[y + 32 + b + a], blockR.v[y + 64 + b + a], blockR.v[y + 96 + b + a]);
		GBLOCK(blockR.v[y + b + a], blockR.v[y + 32 + b1 + a1], blockR.v[y + 64 + b2 + a2], blockR.v[y + 96 + a3 + b3]);
	}
	barrier(CLK_LOCAL_MEM_FENCE);

	//	xor_copy_block(next_block, &block_tmp, &blockR);

	next_block->v[tid]      = block_tmp.v[tid] ^ blockR.v[tid];
	next_block->v[tid + 32] = block_tmp.v[tid + 32] ^ blockR.v[tid + 32];
	next_block->v[tid + 64] = block_tmp.v[tid + 64] ^ blockR.v[tid + 64];
	next_block->v[tid + 96] = block_tmp.v[tid + 96] ^ blockR.v[tid + 96];

//	((__global ulong4*)next_block->v)[tid] = ((__local ulong4*)block_tmp.v)[tid] ^ ((__local ulong4*)blockR.v)[tid];
#undef GBLOCK
}


//template <const uint32_t slice>
//__global__ __launch_bounds__(128, 1)


__attribute__((reqd_work_group_size(32, 1, 1)))
__kernel void mtp_i(__global uint4  *  DBlock, __global uint4  *  DBlock2, __global uint32_t *block_header, uint32_t slice) {
	uint32_t prev_offset, curr_offset;

	uint64_t  ref_index, ref_lane;
	const uint32_t passs = 0;

	uint32_t lane = get_global_id(0) / 32;
	uint32_t gid = get_global_id(0);

	const uint32_t half_memcost = 2 * 1024 * 1024;
	const uint32_t lane_length = 1048576;
	const uint32_t segment_length = 262144;
	const uint32_t lanes = 4;
	uint32_t index;
	__global struct mem_blk * memory = (__global struct mem_blk *)DBlock;
	__global struct mem_blk * memory2 = (__global struct mem_blk *)DBlock2;
	uint32_t tid = (uint32_t)get_local_id(0);


	//	struct mem_blk *ref_block = NULL, *curr_block = NULL;
	uint32_t BH[8];
	uint32_t ss = slice * segment_length;
	uint32_t ss1 = (slice + 1) * segment_length;

	for (int i = 0; i<8; i++)
		BH[i] = block_header[i];



	uint32_t starting_index = 0;

	if ((0 == passs) && (0 == slice)) {
		starting_index = 2;
	}
	curr_offset = lane * lane_length +
		slice * segment_length + starting_index;

	if (0 == curr_offset % lane_length) {

		prev_offset = curr_offset + lane_length - 1;
	}
	else {

		prev_offset = curr_offset - 1;
	}


	int truc = 0;
	uint64_t TheBlockIndex;

#pragma unroll 1
	for (int i = starting_index; i < segment_length;
		++i, ++curr_offset, ++prev_offset) {
		truc++;

		if ((curr_offset & 0xFFFFF) == 1) {
			prev_offset = curr_offset - 1;
		}

		uint2  pseudo_rand2 = (prev_offset<half_memcost) ? as_uint2(memory[prev_offset].v[0]) : as_uint2(memory2[prev_offset - half_memcost].v[0]);
		ref_lane = ((pseudo_rand2.y)) & 3;

		if ((passs == 0) && (slice == 0))
			ref_lane = lane;

		index = i;
		ref_index = index_alpha(passs, slice, index, pseudo_rand2.x, ref_lane == lane, ss, ss1);

		TheBlockIndex = (ref_lane << 20) + ref_index;

		__global struct mem_blk *  prevblk = (prev_offset<half_memcost) ? &memory[prev_offset] : &memory2[prev_offset - half_memcost];
		__global struct mem_blk *  refblk = (((ref_lane << 20) + ref_index)<half_memcost) ? &memory[(ref_lane << 20) + ref_index] : &memory2[(ref_lane << 20) + ref_index - half_memcost];
		__global struct mem_blk *  curblk = (curr_offset<half_memcost) ? &memory[curr_offset] : &memory2[curr_offset - half_memcost];

		//		fill_block_withIndex(memory + prev_offset, memory + (ref_lane << 20) + ref_index, &memory[curr_offset], 0, BH, (uint32_t)TheBlockIndex);
		fill_block_withIndex(prevblk, refblk, curblk, 0, BH, (uint32_t)TheBlockIndex);
		//	if (get_global_id(0) == 0)
		//		printf("index i = %d \n", i);
	}


}


__attribute__((reqd_work_group_size(256, 1, 1)))
__kernel void mtp_fc(uint32_t threads, __global uint4  *  __restrict__ DBlock, __global uint4  *  __restrict__ DBlock2, __global uint2 *a) {

	uint32_t thread = get_global_id(0);
	const uint32_t half_memcost = 2 * 1024 * 1024;
	const uint64_t blakeInit2_64[8] =
	{
		0x6a09e667f2bdc918UL,
		0xbb67ae8584caa73bUL,
		0x3c6ef372fe94f82bUL,
		0xa54ff53a5f1d36f1UL,
		0x510e527fade682d1UL,
		0x9b05688c2b3e6c1fUL,
		0x1f83d9abfb41bd6bUL,
		0x5be0cd19137e2179UL,
	};



	if (thread < threads) {

		__global const uint4 *    __restrict__ GBlock = (thread<half_memcost) ? &DBlock[thread * 64] : &DBlock2[(thread - half_memcost) * 64];


		//		__global const uint4 *    __restrict__ GBlock = &DBlock[0];

		uint32_t len = 0;
		ulong DataTmp[8];
		for (int i = 0; i<8; i++)
			DataTmp[i] = blakeInit2_64[i];

		#pragma unroll
		for (int i = 0; i < 8; i++) {
			//              len += (i&1!=0)? 32:128;
			len += 128;
			uint16 DataChunk[2];
			DataChunk[0].lo = ((__global uint8*)GBlock)[4 * i + 0];
			DataChunk[0].hi = ((__global uint8*)GBlock)[4 * i + 1];
			DataChunk[1].lo = ((__global uint8*)GBlock)[4 * i + 2];
			DataChunk[1].hi = ((__global uint8*)GBlock)[4 * i + 3];
			ulong DataTmp2[8];
			blake2b_compress4xv2(DataTmp2, DataTmp, (uint64_t*)DataChunk, len, i == 7);
			for (int j = 0; j<8; j++)
				DataTmp[j] = DataTmp2[j];
			//              DataTmp = DataTmp2;
			//                              if(thread == 1) printf("%x %x\n",DataChunk[0].lo.s0, DataTmp[0].x);;
		}
#pragma unroll
		for (int i = 0; i<2; i++)
			a[thread * 2 + i] = as_uint2(DataTmp[i]);

	}

}
