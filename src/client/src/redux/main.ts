import { createStore, combineReducers } from 'redux';
import { uiReducer, UIStore } from './uiStore';
import { inputReducer, InputStore } from './inputStore';
import { outputReducer, OutputStore } from './outputStore';

export type HashTable = { [hash: string]: string[] };

export interface MATTStore {
  ui: UIStore;
  inputs: InputStore;
  outputs: OutputStore;
};

const rootReducer = combineReducers({
  ui: uiReducer,
  inputs: inputReducer, 
  outputs: outputReducer
})

export default createStore(rootReducer);