import { ComponentSet } from './types';

import fabricComponents from './Fabric';
import outputComponents from './Outputs';

const componentSet:ComponentSet = {
  ...fabricComponents, 
  ...outputComponents
}

export default componentSet;