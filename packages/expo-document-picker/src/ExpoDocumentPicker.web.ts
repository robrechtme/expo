import { Platform } from 'expo-modules-core';

import { DocumentPickerOptions, DocumentPickerResult } from './types';

export default {
  get name(): string {
    return 'ExpoDocumentPicker';
  },

  async getDocumentAsync({
    type = '*/*',
    multiple = false,
  }: DocumentPickerOptions): Promise<DocumentPickerResult> {
    // SSR guard
    if (!Platform.isDOMAvailable) {
      return { canceled: true, assets: null };
    }

    const input = document.createElement('input');
    input.style.display = 'none';
    input.setAttribute('type', 'file');
    input.setAttribute('accept', Array.isArray(type) ? type.join(',') : type);
    input.setAttribute('id', String(Math.random()));
    if (multiple) {
      input.setAttribute('multiple', 'multiple');
    }

    document.body.appendChild(input);

    return new Promise((resolve, reject) => {
      input.addEventListener('change', () => {
        if (input.files) {
          const targetFile = input.files[0];
          const mimeType = targetFile.type;
          const reader = new FileReader();
          reader.onerror = () => {
            reject(new Error(`Failed to read the selected media because the operation failed.`));
          };
          reader.onload = ({ target }) => {
            const uri = (target as any).result;
            resolve({
              canceled: false,
              type: 'success',
              uri,
              mimeType,
              assets: [],
              name: targetFile.name,
              file: targetFile,
              lastModified: targetFile.lastModified,
              size: targetFile.size,
              output: input.files,
            });
          };
          // Read in the image file as a binary string.
          reader.readAsDataURL(targetFile);
        } else {
          resolve({ canceled: true, assets: null });
        }

        document.body.removeChild(input);
      });

      const event = new MouseEvent('click');
      input.dispatchEvent(event);
    });
  },
};
