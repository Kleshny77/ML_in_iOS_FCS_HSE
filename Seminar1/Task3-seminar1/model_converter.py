import torch
import torchvision
import coremltools as ct

PT_PATH = "model.pt"
MLMODEL_PATH = "ImageClassifier.mlmodel"

def export_torchscript():
    model = torchvision.models.mobilenet_v2(weights="DEFAULT")
    model.eval()

    example_input = torch.randn(1, 3, 224, 224)

    ts_model = torch.jit.trace(model, example_input)
    ts_model.save(PT_PATH)
    print("Saved TorchScript:", PT_PATH)

def convert_to_coreml():
    ts_model = torch.jit.load(PT_PATH, map_location="cpu")
    ts_model.eval()

    mlmodel = ct.convert(
        ts_model,
        inputs=[ct.TensorType(name="input", shape=(1, 3, 224, 224))],
        convert_to="neuralnetwork",
    )

    mlmodel.save(MLMODEL_PATH)
    print("Saved Core ML:", MLMODEL_PATH)

if __name__ == "__main__":
    export_torchscript()
    convert_to_coreml()
