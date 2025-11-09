import os

base_dir = "/root/project_gitlab/projects/home/nginx/frontend/public/images/estates"

for folder_name in os.listdir(base_dir):
    folder_path = os.path.join(base_dir, folder_name)
    
    if os.path.isdir(folder_path):
        # Get only image files
        photos = [f for f in os.listdir(folder_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        
        # Sort to keep consistent order (optional)
        photos.sort()
        
        for i, filename in enumerate(photos, start=1):
            ext = os.path.splitext(filename)[1].lower()  # Keep the original extension
            new_name = f"{i}{ext}"
            old_path = os.path.join(folder_path, filename)
            new_path = os.path.join(folder_path, new_name)
            
            os.rename(old_path, new_path)
        
        print(f"✅ Renamed {len(photos)} photos in folder: {folder_name}")
