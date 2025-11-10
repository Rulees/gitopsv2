import os
import cv2

# Укажите путь к папке 'estates'
# Убедитесь, что этот путь правильный для вашей системы!
base_path = '/root/project_gitlab/projects/home/nginx/frontend/public/images/estates'

def convert_images_in_folder(folder_path):
    """
    Конвертирует все PNG и JPEG файлы в JPG в указанной папке с помощью OpenCV.
    """
    for filename in os.listdir(folder_path):
        # Проверяем, является ли файл изображением PNG или JPEG
        if filename.endswith(('.png', '.jpeg')):
            full_path = os.path.join(folder_path, filename)
            
            try:
                # Читаем изображение с помощью OpenCV
                img = cv2.imread(full_path)
                
                # Проверяем, удалось ли загрузить изображение
                if img is None:
                    print(f"Ошибка: Не удалось загрузить файл {filename}. Возможно, он поврежден.")
                    continue

                # Создаем имя нового файла с расширением .jpg
                new_filename = os.path.splitext(filename)[0] + '.jpg'
                new_full_path = os.path.join(folder_path, new_filename)
                
                # OpenCV по умолчанию работает в формате BGR.
                # Для конвертации в JPG достаточно просто сохранить.
                # cv2.imwrite() автоматически обрабатывает этот процесс.
                cv2.imwrite(new_full_path, img)
                print(f"Конвертировано: {filename} -> {new_filename}")
                
                # Удаляем старый файл
                os.remove(full_path)
                print(f"Удалено: {filename}")
            
            except Exception as e:
                print(f"Ошибка при обработке файла {filename}: {e}")

# Проходимся по всем папкам внутри 'estates'
if os.path.isdir(base_path):
    for estate_id in os.listdir(base_path):
        subfolder_path = os.path.join(base_path, estate_id)
        
        # Убеждаемся, что это папка, а не файл
        if os.path.isdir(subfolder_path):
            print(f"Обработка папки: {subfolder_path}")
            convert_images_in_folder(subfolder_path)
else:
    print(f"Ошибка: Путь {base_path} не найден или не является папкой.")

print("Готово!")
