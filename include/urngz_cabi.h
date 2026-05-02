#ifndef URNGZ_CABI_H
#define URNGZ_CABI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct urngz_sfc32 urngz_sfc32;
typedef struct urngz_sfc32x16 urngz_sfc32x16;
typedef struct urngz_pcg32 urngz_pcg32;
typedef struct urngz_pcg32x8 urngz_pcg32x8;
typedef struct urngz_jsf32 urngz_jsf32;
typedef struct urngz_jsf32x16 urngz_jsf32x16;
typedef struct urngz_xoshiro128ss urngz_xoshiro128ss;
typedef struct urngz_xoshiro128ssx16 urngz_xoshiro128ssx16;
typedef struct urngz_xoshiro128pp urngz_xoshiro128pp;
typedef struct urngz_xoshiro128ppx16 urngz_xoshiro128ppx16;

urngz_sfc32* sfc32_new(uint32_t seed);
void sfc32_free(urngz_sfc32* rng);
void sfc32_nextu(urngz_sfc32* rng, uint32_t* out, size_t count);
void sfc32_nextf(urngz_sfc32* rng, float* out, size_t count);
void sfc32_randi(urngz_sfc32* rng, int32_t* out, int32_t min, int32_t max,
                 size_t count);
void sfc32_randf(urngz_sfc32* rng, float* out, float min, float max,
                 size_t count);

urngz_sfc32x16* sfc32x16_new(uint32_t seed);
void sfc32x16_free(urngz_sfc32x16* rng);
void sfc32x16_nextu(urngz_sfc32x16* rng, uint32_t* out, size_t count);
void sfc32x16_nextf(urngz_sfc32x16* rng, float* out, size_t count);
void sfc32x16_randi(urngz_sfc32x16* rng, int32_t* out, int32_t min, int32_t max,
                    size_t count);
void sfc32x16_randf(urngz_sfc32x16* rng, float* out, float min, float max,
                    size_t count);

urngz_pcg32* pcg32_new(uint64_t seed);
void pcg32_free(urngz_pcg32* rng);
void pcg32_nextu(urngz_pcg32* rng, uint32_t* out, size_t count);
void pcg32_nextf(urngz_pcg32* rng, float* out, size_t count);
void pcg32_randi(urngz_pcg32* rng, int32_t* out, int32_t min, int32_t max,
                 size_t count);
void pcg32_randf(urngz_pcg32* rng, float* out, float min, float max,
                 size_t count);

urngz_pcg32x8* pcg32x8_new(uint64_t seed);
void pcg32x8_free(urngz_pcg32x8* rng);
void pcg32x8_nextu(urngz_pcg32x8* rng, uint32_t* out, size_t count);
void pcg32x8_nextf(urngz_pcg32x8* rng, float* out, size_t count);
void pcg32x8_randi(urngz_pcg32x8* rng, int32_t* out, int32_t min, int32_t max,
                   size_t count);
void pcg32x8_randf(urngz_pcg32x8* rng, float* out, float min, float max,
                   size_t count);

urngz_jsf32* jsf32_new(uint32_t seed);
void jsf32_free(urngz_jsf32* rng);
void jsf32_nextu(urngz_jsf32* rng, uint32_t* out, size_t count);
void jsf32_nextf(urngz_jsf32* rng, float* out, size_t count);
void jsf32_randi(urngz_jsf32* rng, int32_t* out, int32_t min, int32_t max,
                 size_t count);
void jsf32_randf(urngz_jsf32* rng, float* out, float min, float max,
                 size_t count);

urngz_jsf32x16* jsf32x16_new(uint32_t seed);
void jsf32x16_free(urngz_jsf32x16* rng);
void jsf32x16_nextu(urngz_jsf32x16* rng, uint32_t* out, size_t count);
void jsf32x16_nextf(urngz_jsf32x16* rng, float* out, size_t count);
void jsf32x16_randi(urngz_jsf32x16* rng, int32_t* out, int32_t min, int32_t max,
                    size_t count);
void jsf32x16_randf(urngz_jsf32x16* rng, float* out, float min, float max,
                    size_t count);

urngz_xoshiro128pp* xoshiro128pp_new(uint32_t seed);
void xoshiro128pp_free(urngz_xoshiro128pp* rng);
void xoshiro128pp_nextu(urngz_xoshiro128pp* rng, uint32_t* out, size_t count);
void xoshiro128pp_nextf(urngz_xoshiro128pp* rng, float* out, size_t count);
void xoshiro128pp_randi(urngz_xoshiro128pp* rng, int32_t* out, int32_t min,
                        int32_t max, size_t count);
void xoshiro128pp_randf(urngz_xoshiro128pp* rng, float* out, float min,
                        float max, size_t count);

urngz_xoshiro128ss* xoshiro128ss_new(uint32_t seed);
void xoshiro128ss_free(urngz_xoshiro128ss* rng);
void xoshiro128ss_nextu(urngz_xoshiro128ss* rng, uint32_t* out, size_t count);
void xoshiro128ss_nextf(urngz_xoshiro128ss* rng, float* out, size_t count);
void xoshiro128ss_randi(urngz_xoshiro128ss* rng, int32_t* out, int32_t min,
                        int32_t max, size_t count);
void xoshiro128ss_randf(urngz_xoshiro128ss* rng, float* out, float min,
                        float max, size_t count);

urngz_xoshiro128ppx16* xoshiro128ppx16_new(uint32_t seed);
void xoshiro128ppx16_free(urngz_xoshiro128ppx16* rng);
void xoshiro128ppx16_nextu(urngz_xoshiro128ppx16* rng, uint32_t* out,
                           size_t count);
void xoshiro128ppx16_nextf(urngz_xoshiro128ppx16* rng, float* out,
                           size_t count);
void xoshiro128ppx16_randi(urngz_xoshiro128ppx16* rng, int32_t* out,
                           int32_t min, int32_t max, size_t count);
void xoshiro128ppx16_randf(urngz_xoshiro128ppx16* rng, float* out, float min,
                           float max, size_t count);

urngz_xoshiro128ssx16* xoshiro128ssx16_new(uint32_t seed);
void xoshiro128ssx16_free(urngz_xoshiro128ssx16* rng);
void xoshiro128ssx16_nextu(urngz_xoshiro128ssx16* rng, uint32_t* out,
                           size_t count);
void xoshiro128ssx16_nextf(urngz_xoshiro128ssx16* rng, float* out,
                           size_t count);
void xoshiro128ssx16_randi(urngz_xoshiro128ssx16* rng, int32_t* out,
                           int32_t min, int32_t max, size_t count);
void xoshiro128ssx16_randf(urngz_xoshiro128ssx16* rng, float* out, float min,
                           float max, size_t count);

#ifdef __cplusplus
}
#endif

#endif