/*
 * Copyright (c) 2019, Alliance for Open Media. All rights reserved
 *
 * This source code is subject to the terms of the BSD 2 Clause License and
 * the Alliance for Open Media Patent License 1.0. If the BSD 2 Clause License
 * was not distributed with this source code in the LICENSE file, you can
 * obtain it at www.aomedia.org/license/software. If the Alliance for Open
 * Media Patent License 1.0 was not distributed with this source code in the
 * PATENTS file, you can obtain it at www.aomedia.org/license/patent.
 */

#include <assert.h>
#include <emmintrin.h>
#include "config/aom_dsp_rtcd.h"
#include "aom/aom_integer.h"
#include "av1/encoder/av1_quantize.h"
#include "aom_dsp/x86/quantize_x86.h"

void aom_quantize_b_adaptive_sse2(
    const tran_low_t *coeff_ptr, intptr_t n_coeffs, const int16_t *zbin_ptr,
    const int16_t *round_ptr, const int16_t *quant_ptr,
    const int16_t *quant_shift_ptr, tran_low_t *qcoeff_ptr,
    tran_low_t *dqcoeff_ptr, const int16_t *dequant_ptr, uint16_t *eob_ptr,
    const int16_t *scan, const int16_t *iscan) {
  const __m128i zero = _mm_setzero_si128();
  int index = 16;
  int non_zero_count = (int)n_coeffs;
  __m128i zbin, round, quant, dequant, shift;
  __m128i coeff0, coeff1, coeff0_sign, coeff1_sign;
  __m128i qcoeff0, qcoeff1;
  __m128i cmp_mask0, cmp_mask1;
  __m128i eob = zero, eob0, prescan0, prescan1, all_zero;
  const int zbins[2] = { ROUND_POWER_OF_TWO(zbin_ptr[0], 0),
                         ROUND_POWER_OF_TWO(zbin_ptr[1], 0) };

  int prescan_add[2];
  for (int i = 0; i < 2; ++i)
    prescan_add[i] = ROUND_POWER_OF_TWO(dequant_ptr[i] * EOB_FACTOR, 7);

  // max buffer is of size 256 as this functions calls with
  // maximum n_coeffs as 256
  int16_t prescan[256];
  memset(prescan, -1, n_coeffs * sizeof(int16_t));

  // TODO(Aniket): Experiment the following loop with intrinsic
  for (int i = (int)n_coeffs - 1; i >= 0; i--) {
    const int rc = scan[i];
    const qm_val_t wt = 1 << AOM_QM_BITS;
    const int coeff = coeff_ptr[rc] * wt;
    const int coeff_sign = (coeff >> 31);
    const int abs_coeff = (coeff ^ coeff_sign) - coeff_sign;
    const int prescan_add_val = prescan_add[rc != 0];
    if (abs_coeff < (zbins[rc != 0] * (1 << AOM_QM_BITS) + prescan_add_val)) {
      prescan[rc] = 0;
      non_zero_count--;
    } else {
      break;
    }
  }
#if SKIP_EOB_FACTOR_ADJUST
  int first = -1;
#endif
  // Setup global values.
  load_b_values(zbin_ptr, &zbin, round_ptr, &round, quant_ptr, &quant,
                dequant_ptr, &dequant, quant_shift_ptr, &shift);

  // Do DC and first 15 AC.
  coeff0 = load_coefficients(coeff_ptr);
  coeff1 = load_coefficients(coeff_ptr + 8);

  // Poor man's abs().
  coeff0_sign = _mm_srai_epi16(coeff0, 15);
  coeff1_sign = _mm_srai_epi16(coeff1, 15);
  qcoeff0 = invert_sign_sse2(coeff0, coeff0_sign);
  qcoeff1 = invert_sign_sse2(coeff1, coeff1_sign);

  prescan0 = _mm_loadu_si128((const __m128i *)prescan);
  prescan1 = _mm_loadu_si128((const __m128i *)(prescan + 8));

  cmp_mask0 = _mm_and_si128(prescan0, _mm_cmpgt_epi16(qcoeff0, zbin));
  zbin = _mm_unpackhi_epi64(zbin, zbin);  // Switch DC to AC
  cmp_mask1 = _mm_and_si128(prescan1, _mm_cmpgt_epi16(qcoeff1, zbin));

  all_zero = _mm_or_si128(cmp_mask0, cmp_mask1);
  if (_mm_movemask_epi8(all_zero) == 0) {
    _mm_store_si128((__m128i *)(qcoeff_ptr), zero);
    _mm_store_si128((__m128i *)(qcoeff_ptr + 4), zero);
    _mm_store_si128((__m128i *)(qcoeff_ptr + 8), zero);
    _mm_store_si128((__m128i *)(qcoeff_ptr + 12), zero);
    _mm_store_si128((__m128i *)(dqcoeff_ptr), zero);
    _mm_store_si128((__m128i *)(dqcoeff_ptr + 4), zero);
    _mm_store_si128((__m128i *)(dqcoeff_ptr + 8), zero);
    _mm_store_si128((__m128i *)(dqcoeff_ptr + 12), zero);
    round = _mm_unpackhi_epi64(round, round);
    quant = _mm_unpackhi_epi64(quant, quant);
    shift = _mm_unpackhi_epi64(shift, shift);
    dequant = _mm_unpackhi_epi64(dequant, dequant);
  } else {
    calculate_qcoeff(&qcoeff0, round, quant, shift);

    round = _mm_unpackhi_epi64(round, round);
    quant = _mm_unpackhi_epi64(quant, quant);
    shift = _mm_unpackhi_epi64(shift, shift);

    calculate_qcoeff(&qcoeff1, round, quant, shift);

    // Reinsert signs
    qcoeff0 = invert_sign_sse2(qcoeff0, coeff0_sign);
    qcoeff1 = invert_sign_sse2(qcoeff1, coeff1_sign);

    // Mask out zbin threshold coeffs
    qcoeff0 = _mm_and_si128(qcoeff0, cmp_mask0);
    qcoeff1 = _mm_and_si128(qcoeff1, cmp_mask1);

    store_coefficients(qcoeff0, qcoeff_ptr);
    store_coefficients(qcoeff1, qcoeff_ptr + 8);

    coeff0 = calculate_dqcoeff(qcoeff0, dequant);
    dequant = _mm_unpackhi_epi64(dequant, dequant);
    coeff1 = calculate_dqcoeff(qcoeff1, dequant);

    store_coefficients(coeff0, dqcoeff_ptr);
    store_coefficients(coeff1, dqcoeff_ptr + 8);

    eob = scan_for_eob(&coeff0, &coeff1, cmp_mask0, cmp_mask1, iscan, 0, zero);
  }

  // AC only loop.
  // TODO(Aniket): Reduce the processing of coeff quatization
  // based on eob logic
  while (index < n_coeffs) {
    coeff0 = load_coefficients(coeff_ptr + index);
    coeff1 = load_coefficients(coeff_ptr + index + 8);

    coeff0_sign = _mm_srai_epi16(coeff0, 15);
    coeff1_sign = _mm_srai_epi16(coeff1, 15);
    qcoeff0 = invert_sign_sse2(coeff0, coeff0_sign);
    qcoeff1 = invert_sign_sse2(coeff1, coeff1_sign);

    prescan0 = _mm_loadu_si128((const __m128i *)(prescan + index));
    prescan1 = _mm_loadu_si128((const __m128i *)(prescan + index + 8));

    cmp_mask0 = _mm_and_si128(prescan0, _mm_cmpgt_epi16(qcoeff0, zbin));
    cmp_mask1 = _mm_and_si128(prescan1, _mm_cmpgt_epi16(qcoeff1, zbin));

    all_zero = _mm_or_si128(cmp_mask0, cmp_mask1);
    if (_mm_movemask_epi8(all_zero) == 0) {
      _mm_store_si128((__m128i *)(qcoeff_ptr + index), zero);
      _mm_store_si128((__m128i *)(qcoeff_ptr + index + 4), zero);
      _mm_store_si128((__m128i *)(qcoeff_ptr + index + 8), zero);
      _mm_store_si128((__m128i *)(qcoeff_ptr + index + 12), zero);
      _mm_store_si128((__m128i *)(dqcoeff_ptr + index), zero);
      _mm_store_si128((__m128i *)(dqcoeff_ptr + index + 4), zero);
      _mm_store_si128((__m128i *)(dqcoeff_ptr + index + 8), zero);
      _mm_store_si128((__m128i *)(dqcoeff_ptr + index + 12), zero);
      index += 16;
      continue;
    }
    calculate_qcoeff(&qcoeff0, round, quant, shift);
    calculate_qcoeff(&qcoeff1, round, quant, shift);

    qcoeff0 = invert_sign_sse2(qcoeff0, coeff0_sign);
    qcoeff1 = invert_sign_sse2(qcoeff1, coeff1_sign);

    qcoeff0 = _mm_and_si128(qcoeff0, cmp_mask0);
    qcoeff1 = _mm_and_si128(qcoeff1, cmp_mask1);

    store_coefficients(qcoeff0, qcoeff_ptr + index);
    store_coefficients(qcoeff1, qcoeff_ptr + index + 8);

    coeff0 = calculate_dqcoeff(qcoeff0, dequant);
    coeff1 = calculate_dqcoeff(qcoeff1, dequant);

    store_coefficients(coeff0, dqcoeff_ptr + index);
    store_coefficients(coeff1, dqcoeff_ptr + index + 8);

    eob0 = scan_for_eob(&coeff0, &coeff1, cmp_mask0, cmp_mask1, iscan, index,
                        zero);
    eob = _mm_max_epi16(eob, eob0);
    index += 16;
  }

  *eob_ptr = accumulate_eob(eob);

#if SKIP_EOB_FACTOR_ADJUST
  // TODO(Aniket): Experiment the following loop with intrinsic by combining
  // with the quantization loop above
  for (int i = 0; i < non_zero_count; i++) {
    const int rc = scan[i];
    const int qcoeff = qcoeff_ptr[rc];
    if (qcoeff) {
      first = i;
      break;
    }
  }
  if ((*eob_ptr - 1) >= 0 && first == (*eob_ptr - 1)) {
    const int rc = scan[(*eob_ptr - 1)];
    if (qcoeff_ptr[rc] == 1 || qcoeff_ptr[rc] == -1) {
      const qm_val_t wt = (1 << AOM_QM_BITS);
      const int coeff = coeff_ptr[rc] * wt;
      const int coeff_sign = (coeff >> 31);
      const int abs_coeff = (coeff ^ coeff_sign) - coeff_sign;
      const int factor = EOB_FACTOR + SKIP_EOB_FACTOR_ADJUST;
      const int prescan_add_val =
          ROUND_POWER_OF_TWO(dequant_ptr[rc != 0] * factor, 7);
      if (abs_coeff < (zbins[rc != 0] * (1 << AOM_QM_BITS) + prescan_add_val)) {
        qcoeff_ptr[rc] = 0;
        dqcoeff_ptr[rc] = 0;
        *eob_ptr = 0;
      }
    }
  }
#endif
}
