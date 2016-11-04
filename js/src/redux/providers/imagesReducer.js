// Copyright 2015, 2016 Ethcore (UK) Ltd.
// This file is part of Parity.

// Parity is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Parity is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Parity.  If not, see <http://www.gnu.org/licenses/>.

import { handleActions } from 'redux-actions';
import { bytesToHex } from '../../api/util/format';

import { parityNode } from '../../environment';

const ZERO = '0x0000000000000000000000000000000000000000000000000000000000000000';

const initialState = {
  images: {},
  icons: {}
};

export function hashToImageUrl (hashArray) {
  const hash = hashArray ? bytesToHex(hashArray) : ZERO;

  return hash === ZERO ? null : `${parityNode}/api/content/${hash.substr(2)}`;
}

export default handleActions({
  setAddressImage (state, action) {
    const { address, hashArray } = action;

    return Object.assign({}, state, {
      [address]: hashToImageUrl(hashArray)
    });
  },

  memorizeIcon (state, action) {
    const { address, scale, iconsrc } = action;

    const icons = { ...state.icons };
    const addressIcons = icons[address] || {};

    return Object.assign({}, state, {
      icons: {
        ...icons,
        [address]: {
          ...addressIcons,
          [scale]: iconsrc
        }
      }
    });
  }
}, initialState);
